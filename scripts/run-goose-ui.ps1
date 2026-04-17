# Goose Desktop UI Runner - Windows
#
# If blocked by execution policy:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $PROJECT_DIR

Write-Host "=================================================="
Write-Host "  GOOSE DESKTOP UI LAUNCHER"
Write-Host "=================================================="
Write-Host ""

# Check if Goose Desktop is installed
$gooseExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Goose Desktop" -Recurse -Filter "Goose.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $gooseExe) {
    Write-Host "Goose Desktop UI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install it first: scripts\install-goose-ui.ps1"
    exit 1
}
Write-Host "Goose Desktop UI found: $($gooseExe.FullName)" -ForegroundColor Green

# Ensure Ollama is running
$ollamaUp = $false
try {
    $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3
    $ollamaUp = $true
} catch {}

if (-not $ollamaUp) {
    Write-Host "Ollama not running. Starting..." -ForegroundColor Yellow
    $svc = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue
    if ($svc) {
        Start-Service "Ollama" -ErrorAction SilentlyContinue
    } else {
        Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    }
    Start-Sleep -Seconds 5
    try {
        $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 5
        $ollamaUp = $true
    } catch {}
}
if (-not $ollamaUp) {
    Write-Host "Ollama not responding. Start it manually: ollama serve" -ForegroundColor Red
    exit 1
}

# Check cloud models
$models = ollama list 2>&1 | Out-String
$cloudModels = ($models -split "`n" | Where-Object { $_ -match ":cloud" })
$cloudCount = $cloudModels.Count

if ($cloudCount -eq 0) {
    Write-Host "No cloud models found. Run: ollama signin; ollama pull qwen3.5:cloud" -ForegroundColor Yellow
} else {
    Write-Host "Cloud models available: $cloudCount" -ForegroundColor Green
    $cloudModels | Select-Object -First 5 | ForEach-Object {
        $name = ($_ -split "\s+")[0]
        Write-Host "  - $name"
    }
}

Write-Host ""
# Goose 1.30 moved its config path — ask the binary rather than guess
$configPath = $null
try {
    $infoOut = (& goose info 2>&1 | Out-String)
    if ($infoOut -match 'Config yaml:\s*(\S[^\r\n]*?)\s*$') { $configPath = $Matches[1].Trim() }
} catch {}
if (-not $configPath) { $configPath = Join-Path $env:APPDATA "Block\goose\config\config.yaml" }
$configuredModel = $null
if (Test-Path $configPath) {
    $configuredModel = (Select-String -Path $configPath -Pattern "^GOOSE_MODEL:" -ErrorAction SilentlyContinue | ForEach-Object { ($_.Line -split '\s+', 2)[1] })
}
if (-not $configuredModel) { $configuredModel = "qwen3.5:cloud" }

Write-Host "Configuration:" -ForegroundColor Blue
Write-Host "  Provider: Ollama (Cloud Models)"
Write-Host "  Default Model: $configuredModel"
Write-Host "  Skills: 31 auto-discovered"
Write-Host ""

# Activate Python venv
$venvActivate = Join-Path $PROJECT_DIR "venv\Scripts\Activate.ps1"
if (Test-Path $venvActivate) {
    & $venvActivate
}

# Set environment variables
$env:GOOSE_PROVIDER = "ollama"
$env:GOOSE_MODEL = $configuredModel

Write-Host "Launching Goose Desktop UI..." -ForegroundColor Green
Write-Host ""

# Launch the desktop application
Start-Process $gooseExe.FullName -WorkingDirectory $PROJECT_DIR

Write-Host "Goose Desktop UI launched." -ForegroundColor Green
Write-Host ""
Write-Host "Tips:"
Write-Host "  - Configure providers in Settings > Configure Providers"
Write-Host "  - Switch models in Settings > Models"
Write-Host "  - All 31 skills are available through the chat interface"
Write-Host "  - Sessions are shared between CLI and Desktop UI"
