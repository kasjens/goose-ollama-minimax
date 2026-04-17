# Goose + Ollama MiniMax - One-Step Setup for Windows 11
#
# If you see "running scripts is disabled on this system", run this first:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# Then re-run: .\setup.ps1

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PROJECT_DIR

function Step  { param($n,$msg) Write-Host "`n[$n/9] $msg" -ForegroundColor Blue }
function Ok    { param($msg)    Write-Host "  OK $msg" -ForegroundColor Green }
function Warn  { param($msg)    Write-Host "  !! $msg" -ForegroundColor Yellow }
function Fail  { param($msg)    Write-Host "  FAIL $msg" -ForegroundColor Red; exit 1 }

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

# -- 1. Prerequisites --------------------------------------------------------
Step 1 "Checking prerequisites..."

# Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Python..."
    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements --silent
    Refresh-Path
}
if (Get-Command python -ErrorAction SilentlyContinue) {
    Ok "Python $(python --version 2>&1)"
} else {
    Fail "Python not found. Install from https://www.python.org/downloads/"
}

# Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Git..."
    winget install Git.Git --accept-source-agreements --accept-package-agreements --silent
    Refresh-Path
}
if (Get-Command git -ErrorAction SilentlyContinue) {
    Ok "Git installed"
} else {
    Fail "Git not found. Install from https://git-scm.com/"
}

# -- 2. Ollama ---------------------------------------------------------------
Step 2 "Checking Ollama..."

Refresh-Path
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Ollama (official installer)..."
    irm https://ollama.com/install.ps1 | iex
    Refresh-Path
    Start-Sleep -Seconds 3
}
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Ok "Ollama installed"
} else {
    Fail "Ollama not found. Install from https://ollama.com/download"
}

# -- 3. Ollama service -------------------------------------------------------
Step 3 "Ensuring Ollama is running..."

$ollamaUp = $false
try {
    $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3
    $ollamaUp = $true
} catch {}

if (-not $ollamaUp) {
    # Try Windows Service first
    $svc = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Running') {
        Start-Service "Ollama" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    } else {
        # Fall back to starting ollama serve in background
        Write-Host "  Starting ollama serve..."
        Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }
    try {
        $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 5
        $ollamaUp = $true
    } catch {}
}

if ($ollamaUp) {
    Ok "Ollama service is running"
} else {
    Fail "Could not start Ollama. Try manually: ollama serve"
}

# -- 4. Ollama cloud sign-in -------------------------------------------------
Step 4 "Checking Ollama cloud sign-in..."

# Ollama writes progress to stderr - temporarily allow errors
$ErrorActionPreference = "Continue"

$models = ollama list 2>&1 | Out-String
if ($models -match ":cloud") {
    $ErrorActionPreference = "Stop"
    Ok "Signed in to Ollama cloud"
} else {
    $pullResult = ollama pull qwen3.5:cloud 2>&1 | Out-String
    if ($pullResult -match "success|up to date") {
        $ErrorActionPreference = "Stop"
        Ok "Signed in to Ollama cloud"
    } else {
        Warn "You need to sign in to Ollama for cloud model access."
        Write-Host ""
        Write-Host "  Run this now (it will open a browser link):"
        Write-Host "    ollama signin"
        Write-Host ""
        Read-Host "  Press Enter after you have signed in"
        $pullResult2 = ollama pull qwen3.5:cloud 2>&1 | Out-String
        $ErrorActionPreference = "Stop"
        if ($pullResult2 -notmatch "success|up to date") {
            Fail "Still not signed in. Run 'ollama signin' and try setup again."
        }
        Ok "Signed in to Ollama cloud"
    }
}

# -- 5. Fetch and pull cloud models ------------------------------------------
Step 5 "Fetching latest cloud models from ollama.com..."

$ErrorActionPreference = "Continue"

# Discover all available cloud models dynamically
Write-Host "  Querying ollama.com for cloud models..."
$cloudTags = @()
try {
    $html = Invoke-WebRequest -Uri "https://ollama.com/search?c=cloud" -UseBasicParsing -TimeoutSec 15
    $modelNames = [regex]::Matches($html.Content, 'href="/library/([^"]*)"') |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -notmatch '/' } |
        Sort-Object -Unique

    foreach ($modelName in $modelNames) {
        try {
            $tagsHtml = Invoke-WebRequest -Uri "https://ollama.com/library/$modelName/tags" -UseBasicParsing -TimeoutSec 10
            $tags = [regex]::Matches($tagsHtml.Content, "href=""/library/${modelName}:([^""]*cloud[^""]*)""") |
                ForEach-Object { "${modelName}:$($_.Groups[1].Value)" } |
                Sort-Object -Unique
            foreach ($tag in $tags) {
                $cloudTags += $tag
            }
        } catch {}
    }
} catch {}

if ($cloudTags.Count -eq 0) {
    Warn "Could not fetch model list from ollama.com - falling back to defaults"
    $cloudTags = @("qwen3.5:cloud", "qwen3-coder:480b-cloud", "deepseek-v3.1:671b-cloud", "gemma4:31b-cloud")
} else {
    Ok "Found $($cloudTags.Count) cloud models on ollama.com"
}

# Get currently installed cloud models
$installedRaw = ollama list 2>&1 | Out-String
$installedModels = @()
foreach ($line in ($installedRaw -split "`n")) {
    if ($line -match ":.*cloud") {
        $name = ($line -split "\s+")[0]
        if ($name) { $installedModels += $name }
    }
}

Write-Host ""
Write-Host "  Available cloud models:"
foreach ($tag in $cloudTags) {
    if ($installedModels -contains $tag) {
        Write-Host "    [installed] $tag" -ForegroundColor Green
    } else {
        Write-Host "    [new]       $tag" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  1) Pull all cloud models ($($cloudTags.Count) total)"
Write-Host "  2) Pull only new/missing models"
Write-Host "  3) Skip (keep current models)"
$modelChoice = Read-Host "  Choice [1-3, default=1]"
if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "1" }

if ($modelChoice -ne "3") {
    foreach ($tag in $cloudTags) {
        if ($installedModels -contains $tag) {
            Ok "$tag already pulled"
        } else {
            Write-Host "  Pulling $tag ..."
            ollama pull $tag 2>&1 | Out-Null
            Ok "$tag pulled"
        }
    }
}

# Remove models no longer available on ollama.com
foreach ($installed in $installedModels) {
    if ($cloudTags -notcontains $installed) {
        Write-Host "  [obsolete] $installed is no longer on ollama.com" -ForegroundColor Red
        $rmReply = Read-Host "  Remove $installed? [Y/n]"
        if ($rmReply -ne 'n' -and $rmReply -ne 'N') {
            ollama rm $installed 2>&1 | Out-Null
            Ok "Removed $installed"
        }
    }
}

$ErrorActionPreference = "Stop"

# -- 6. Python virtual environment -------------------------------------------
Step 6 "Setting up Python environment..."

$venvActivate = Join-Path $PROJECT_DIR "venv\Scripts\Activate.ps1"

if (-not (Test-Path $venvActivate)) {
    # Remove broken venv if exists
    $venvDir = Join-Path $PROJECT_DIR "venv"
    if (Test-Path $venvDir) { Remove-Item $venvDir -Recurse -Force }
    Write-Host "  Creating virtual environment..."
    python -m venv venv
    if (-not (Test-Path $venvActivate)) {
        Fail "venv creation failed"
    }
    Ok "Virtual environment created"
} else {
    Ok "Virtual environment already exists"
}

Write-Host "  Installing pip packages (this may take a few minutes)..."
& $venvActivate
$ErrorActionPreference = "Continue"
pip install --upgrade pip 2>&1 | Out-Null
pip install -r config\requirements-core.txt 2>&1 | Select-String "^(Collecting|Installing|Successfully)" | ForEach-Object { "  $_" }
$ErrorActionPreference = "Stop"
deactivate
Ok "Python dependencies installed"

# -- 7. Skills integration ----------------------------------------------------
Step 7 "Integrating skills..."

$skillsDir = Join-Path $PROJECT_DIR ".agents\skills"
$skillCount = 0
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue).Count
}

if ($skillCount -eq 0) {
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null

    if (-not (Test-Path "anthropic-skills")) {
        Write-Host "  Cloning Anthropic skills..."
        git clone --depth 1 -q https://github.com/anthropics/skills.git anthropic-skills
    }
    if (-not (Test-Path "minimax-skills")) {
        Write-Host "  Cloning MiniMax skills..."
        git clone --depth 1 -q https://github.com/MiniMax-AI/skills.git minimax-skills
    }

    if (Test-Path "anthropic-skills\skills") {
        Copy-Item -Recurse -Force "anthropic-skills\skills\*" $skillsDir -ErrorAction SilentlyContinue
    }
    if (Test-Path "minimax-skills\skills") {
        Copy-Item -Recurse -Force "minimax-skills\skills\*" $skillsDir -ErrorAction SilentlyContinue
    }

    $skillCount = (Get-ChildItem $skillsDir -Directory).Count
    Ok "$skillCount skills integrated"
} else {
    Ok "$skillCount skills already available"
}

# Junction in home directory so Desktop UI discovers skills
$homeAgents = Join-Path $env:USERPROFILE ".agents"
if (-not (Test-Path $homeAgents)) {
    cmd /c mklink /J "$homeAgents" "$PROJECT_DIR\.agents" | Out-Null
    Ok "Created .agents junction for Desktop UI skill discovery"
} elseif ((Get-Item $homeAgents).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    Ok ".agents junction already exists"
}

# -- 8. Goose AI --------------------------------------------------------------
Step 8 "Checking Goose AI (always fetching latest release)..."

# Force TLS 1.2 — PowerShell 5.1 defaults to TLS 1.0 which GitHub rejects,
# causing the release-check API call to fail silently in earlier runs.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$gooseDir = Join-Path $env:LOCALAPPDATA "Programs\goose"
# Add to session PATH
if (Test-Path $gooseDir) { $env:Path = "$gooseDir;$env:Path" }

# Always query GitHub for the latest release tag — never pins to a fixed version.
Write-Host "  Querying GitHub for the latest Goose release..."
$latestTag = $null
try {
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/aaif-goose/goose/releases/latest" -UseBasicParsing
    $latestTag = $releaseInfo.tag_name -replace '^v', ''
    if ($latestTag) { Write-Host "  Latest Goose release on GitHub: $latestTag" }
} catch {
    Warn "Could not query GitHub ($($_.Exception.Message)) — will still attempt install"
}

$currentVer = $null
if (Get-Command goose -ErrorAction SilentlyContinue) {
    $currentVer = (goose --version 2>&1 | Out-String).Trim() -replace '[^0-9.]', ''
}

$needsInstall = (-not $currentVer)
# If we couldn't determine $latestTag, reinstall anyway so we don't get stuck on an old build.
$needsUpdate = ($currentVer -and (-not $latestTag -or $currentVer -ne $latestTag))

if ($needsInstall -or $needsUpdate) {
    if ($needsUpdate -and $latestTag) {
        Write-Host "  Updating Goose AI ($currentVer -> $latestTag)..."
    } elseif ($needsUpdate) {
        Write-Host "  Reinstalling Goose AI (current: $currentVer, latest: unknown)..."
    } else {
        Write-Host "  Installing Goose AI..."
    }
    New-Item -ItemType Directory -Path $gooseDir -Force | Out-Null

    $zipPath = Join-Path $env:TEMP "goose-windows.zip"
    $url = "https://github.com/aaif-goose/goose/releases/latest/download/goose-x86_64-pc-windows-msvc.zip"
    Write-Host "  Downloading Windows binary..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

    Write-Host "  Extracting..."
    # Extract to temp dir first, then copy to goose dir (avoids locked file issues)
    $extractDir = Join-Path $env:TEMP "goose-extract-$PID"
    Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    # If goose.exe is running (e.g. an open CLI session or Desktop UI), Copy-Item fails silently.
    # Stop any running goose processes before we overwrite.
    $running = Get-Process -Name goose -ErrorAction SilentlyContinue
    if ($running) {
        Warn "goose.exe is running — stopping $($running.Count) process(es) so the update can land"
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }

    # Find goose.exe (may be nested in a subdirectory like goose-package/)
    $gooseExe = Get-ChildItem $extractDir -Recurse -Filter "goose.exe" | Select-Object -First 1
    if ($gooseExe) {
        $targetExe = Join-Path $gooseDir "goose.exe"
        # If the file is still locked, rename the old one aside so the Copy always succeeds
        if (Test-Path $targetExe) {
            try { Remove-Item $targetExe -Force } catch {
                Move-Item $targetExe "$targetExe.old-$PID" -Force -ErrorAction SilentlyContinue
            }
        }
        Copy-Item $gooseExe.FullName $targetExe -Force
        # Also copy any other files from the same directory (DLLs, etc.)
        Get-ChildItem $gooseExe.DirectoryName -File | Where-Object { $_.Name -ne "goose.exe" } | Copy-Item -Destination $gooseDir -Force
        # Clean up any stale .old-* copies from previous runs
        Get-ChildItem $gooseDir -Filter "goose.exe.old-*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    } else {
        Fail "goose.exe not found in downloaded archive"
    }

    Remove-Item $zipPath -ErrorAction SilentlyContinue
    Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue

    # Add to user PATH permanently
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$gooseDir*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$gooseDir;$userPath", "User")
    }
    $env:Path = "$gooseDir;$env:Path"

    if (Get-Command goose -ErrorAction SilentlyContinue) {
        $newVer = (goose --version 2>&1 | Out-String).Trim()
        Ok "Goose AI installed ($newVer)"
    } else {
        Warn "Goose AI installed but may need a new terminal to appear in PATH"
    }
} else {
    Ok "Goose AI up to date ($currentVer)"
}

# Apply config template (preserves GOOSE_MODEL + brave-search if already set)
# Ask Goose where its config lives — path changed in 1.30 (now %APPDATA%\Block\goose\config)
$configPath = $null
try {
    $infoOut = (& goose info 2>&1 | Out-String)
    if ($infoOut -match 'Config yaml:\s*(\S[^\r\n]*?)\s*$') {
        $configPath = $Matches[1].Trim()
    }
} catch {}
if (-not $configPath) {
    $configPath = Join-Path $env:APPDATA "Block\goose\config\config.yaml"
}
$configDir = Split-Path -Parent $configPath
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
$templatePath = Join-Path $PROJECT_DIR "config\goose-config-template.yaml"

# Preserve current model + brave-search block
$currentModel = $null
$braveBlock = $null
if (Test-Path $configPath) {
    $currentModel = (Select-String -Path $configPath -Pattern "^GOOSE_MODEL:" -ErrorAction SilentlyContinue | ForEach-Object { ($_.Line -split '\s+', 2)[1] })
    $lines = Get-Content $configPath
    $inBrave = $false
    $braveLines = @()
    foreach ($line in $lines) {
        if ($line -match '^  brave-search:') { $inBrave = $true; $braveLines += $line; continue }
        if ($inBrave) {
            if ($line -match '^  [a-zA-Z]' -and $line -notmatch '^  brave-search:') { $inBrave = $false; continue }
            $braveLines += $line
        }
    }
    if ($braveLines.Count -gt 0) { $braveBlock = ($braveLines -join "`n") }
}

if (Test-Path $templatePath) {
    Copy-Item $templatePath $configPath -Force
    if ($currentModel) {
        (Get-Content $configPath) -replace '^GOOSE_MODEL: .*', "GOOSE_MODEL: $currentModel" | Set-Content $configPath
    }
    # Re-insert brave-search block above `skills:` so API key wiring survives
    if ($braveBlock -and -not (Select-String -Path $configPath -Pattern '^  brave-search:' -Quiet)) {
        $content = Get-Content $configPath -Raw
        $content = $content -replace '(  skills:)', "$braveBlock`n`$1"
        Set-Content -Path $configPath -Value $content -NoNewline
    }
    Ok "Goose config applied to $configPath"
    # Clean up stale pre-1.30 config so users aren't confused
    $stalePath = Join-Path $env:USERPROFILE ".config\goose\config.yaml"
    if ((Test-Path $stalePath) -and ($stalePath -ne $configPath)) {
        Move-Item $stalePath "$stalePath.stale" -Force -ErrorAction SilentlyContinue
        Ok "Moved pre-1.30 config aside: $stalePath.stale"
    }
} else {
    Warn "Config template not found at $templatePath"
}

# -- 9. Optional extras -------------------------------------------------------
Step 9 "Optional extras..."

Write-Host ""
$depsReply = Read-Host "  Install full ML/AI dependencies (PyTorch, OpenCV, Node.js, FFmpeg)? [y/N]"
if ($depsReply -eq 'y' -or $depsReply -eq 'Y') {
    Write-Host "  Running install-all-dependencies.ps1..."
    & "$PROJECT_DIR\scripts\install-all-dependencies.ps1"
    Ok "Full dependencies installed"
} else {
    Ok "Skipped (run scripts\install-all-dependencies.ps1 later if needed)"
}

Write-Host ""
$braveReply = Read-Host "  Set up Brave Search web integration (free API key)? [y/N]"
if ($braveReply -eq 'y' -or $braveReply -eq 'Y') {
    & "$PROJECT_DIR\scripts\setup-brave-search.ps1"
} else {
    Ok "Skipped (run scripts\setup-brave-search.ps1 later if needed)"
}

# -- Done ---------------------------------------------------------------------
Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Run Goose:  .\run-goose.ps1"
Write-Host "  Validate:   .\validate.ps1"
Write-Host ""
Write-Host "Skills are auto-discovered - just ask naturally:"
Write-Host "  'Create a PowerPoint presentation'"
Write-Host "  'Help me build an iOS app'"
Write-Host "  'Generate a Word document'"
