# Validate Goose + Ollama MiniMax Setup - Windows
# Run: powershell -ExecutionPolicy Bypass -File validate.ps1

$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PROJECT_DIR

$script:Errors = 0; $script:Warnings = 0; $script:TotalChecks = 0

function Check-Pass { param($msg) Write-Host "  PASS $msg" -ForegroundColor Green;  $script:TotalChecks++ }
function Check-Fail { param($msg) Write-Host "  FAIL $msg" -ForegroundColor Red;    $script:Errors++; $script:TotalChecks++ }
function Check-Warn { param($msg) Write-Host "  WARN $msg" -ForegroundColor Yellow; $script:Warnings++; $script:TotalChecks++ }
function Check-Info { param($msg) Write-Host "  INFO $msg" -ForegroundColor Blue }
function Section    { param($msg) Write-Host "`n$msg" -ForegroundColor Magenta }

# Ensure Goose in PATH
$gooseDir = Join-Path $env:LOCALAPPDATA "Programs\goose"
if (Test-Path $gooseDir) { $env:Path = "$gooseDir;$env:Path" }

Write-Host "============================================"
Write-Host "  SETUP VALIDATION (Windows)"
Write-Host "============================================"

# -- Core Tools ---------------------------------------------------------------
Section "Core Tools"

if (Get-Command ollama -ErrorAction SilentlyContinue) {
    $v = ollama --version 2>&1 | Out-String
    Check-Pass "Ollama installed ($($v.Trim()))"
} else { Check-Fail "Ollama not installed" }

if (Get-Command goose -ErrorAction SilentlyContinue) {
    $v = goose --version 2>&1 | Out-String
    Check-Pass "Goose AI installed ($($v.Trim()))"
} else { Check-Fail "Goose AI not found in PATH" }

if (Get-Command python -ErrorAction SilentlyContinue) {
    $v = python --version 2>&1 | Out-String
    Check-Pass "Python installed ($($v.Trim()))"
} else { Check-Fail "Python not installed" }

if (Get-Command git -ErrorAction SilentlyContinue) {
    Check-Pass "Git installed"
} else { Check-Fail "Git not installed" }

if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = node --version 2>&1 | Out-String
    Check-Pass "Node.js installed ($($v.Trim()))"
} else { Check-Info "Node.js not installed (optional)" }

# -- Ollama Service & Model --------------------------------------------------
Section "Ollama Service & Model"

$ollamaUp = $false
try { $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3; $ollamaUp = $true } catch {}
if ($ollamaUp) { Check-Pass "Ollama service running on port 11434" }
else           { Check-Fail "Ollama service not responding" }

$models = ollama list 2>&1 | Out-String
$cloudCount = ($models -split "`n" | Where-Object { $_ -match ":cloud" }).Count
if ($cloudCount -gt 0) {
    Check-Pass "$cloudCount cloud model(s) available"
} else { Check-Fail "No cloud models pulled (run: ollama pull qwen3.5:cloud)" }

# -- Python Environment ------------------------------------------------------
Section "Python Environment"

$venvActivate = Join-Path $PROJECT_DIR "venv\Scripts\Activate.ps1"
if (Test-Path $venvActivate) {
    Check-Pass "Virtual environment exists at .\venv\"
    & $venvActivate

    $coreDeps = @{
        "pandas"      = "pandas"
        "numpy"       = "numpy"
        "pillow"      = "PIL"
        "pypdf"       = "pypdf"
        "python-docx" = "docx"
        "openpyxl"    = "openpyxl"
        "matplotlib"  = "matplotlib"
        "requests"    = "requests"
        "python-pptx" = "pptx"
        "pyyaml"      = "yaml"
        "rich"        = "rich"
    }

    foreach ($dep in $coreDeps.GetEnumerator()) {
        $result = python -c "import $($dep.Value)" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Check-Pass "Python: $($dep.Key)"
        } else {
            Check-Fail "Python: $($dep.Key) missing"
        }
    }

    deactivate
} else {
    Check-Fail "Virtual environment missing (expected at .\venv\)"
}

# -- Skills -------------------------------------------------------------------
Section "Skills"

$skillsDir = Join-Path $PROJECT_DIR ".agents\skills"
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue).Count
    if ($skillCount -gt 20) {
        Check-Pass "$skillCount skills in .agents\skills\"
    } elseif ($skillCount -gt 0) {
        Check-Warn "Only $skillCount skills found (expected ~31)"
    } else {
        Check-Fail ".agents\skills\ is empty"
    }

    if (Test-Path "$skillsDir\docx") { Check-Pass "Document skills" } else { Check-Warn "Document skills missing" }
    if (Test-Path "$skillsDir\pptx") { Check-Pass "PowerPoint skills" } else { Check-Warn "PowerPoint skills missing" }
    if (Test-Path "$skillsDir\frontend-dev") { Check-Pass "Frontend dev skills" } else { Check-Warn "Frontend dev skills missing" }
} else {
    Check-Fail ".agents\skills\ directory missing"
}

# -- Goose Configuration -----------------------------------------------------
Section "Goose Configuration"

$configPath = $null
try {
    $infoOut = (& goose info 2>&1 | Out-String)
    if ($infoOut -match 'Config yaml:\s*(\S[^\r\n]*?)\s*$') { $configPath = $Matches[1].Trim() }
} catch {}
if (-not $configPath) { $configPath = Join-Path $env:APPDATA "Block\goose\config\config.yaml" }
if (Test-Path $configPath) {
    Check-Pass "Goose config file exists ($configPath)"
} else {
    Check-Info "Goose config not yet created (will be created on first run)"
}

# -- System -------------------------------------------------------------------
Section "System"

$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Check-Pass "RAM: ${ram}GB"

$disk = [math]::Round((Get-PSDrive C).Free / 1GB)
Check-Pass "Disk free: ${disk}GB"

# -- Security -----------------------------------------------------------------
Section "Security"

if (Test-Path ".gitignore") { Check-Pass ".gitignore exists" }
else { Check-Warn ".gitignore missing" }

# -- Summary ------------------------------------------------------------------
Write-Host ""
Write-Host "============================================"
$passed = $script:TotalChecks - $script:Errors - $script:Warnings

if ($script:Errors -eq 0 -and $script:Warnings -eq 0) {
    Write-Host "  ALL CHECKS PASSED ($script:TotalChecks/$script:TotalChecks)" -ForegroundColor Green
} elseif ($script:Errors -eq 0) {
    Write-Host "  GOOD - $passed passed, $($script:Warnings) warnings" -ForegroundColor Green
} else {
    Write-Host "  $($script:Errors) ERRORS, $($script:Warnings) warnings out of $script:TotalChecks checks" -ForegroundColor Red
}
Write-Host "============================================"

if ($script:Errors -gt 0) {
    Write-Host ""
    Write-Host "Fix errors above, then re-run: .\validate.ps1"
}

exit $script:Errors
