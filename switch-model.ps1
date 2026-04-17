# Goose Model Switcher for Cloud Models - Windows
#
# If blocked by execution policy:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"

Write-Host "Available Ollama Cloud Models:"
Write-Host "=================================="

$models = @()
$output = ollama list 2>&1 | Out-String -Stream
foreach ($line in $output) {
    if ($line -match ":.*cloud") {
        $name = ($line -split "\s+")[0]
        if ($name) { $models += $name }
    }
}
$models = $models | Sort-Object

if ($models.Count -eq 0) {
    Write-Host "No cloud models found. Run: ollama signin; ollama pull qwen3.5:cloud" -ForegroundColor Red
    exit 1
}

# Ask Goose where its config lives (path changed in 1.30)
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

$currentModel = ""
if (Test-Path $configPath) {
    $configContent = Get-Content $configPath -Raw
    if ($configContent -match "GOOSE_MODEL:\s*(.+)") {
        $currentModel = $Matches[1].Trim()
    }
}

for ($i = 0; $i -lt $models.Count; $i++) {
    $marker = ""
    if ($models[$i] -eq $currentModel) { $marker = " (CURRENT)" }
    Write-Host "  $($i + 1)) $($models[$i])$marker"
}

Write-Host ""
$choice = Read-Host "Select model [1-$($models.Count)]"

if ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $models.Count) {
    $selectedModel = $models[[int]$choice - 1]

    if (Test-Path $configPath) {
        $content = Get-Content $configPath -Raw
        $content = $content -replace "GOOSE_MODEL:\s*.+", "GOOSE_MODEL: $selectedModel"
        Set-Content $configPath $content -NoNewline
    }

    Write-Host "Switched to: $selectedModel" -ForegroundColor Green
    Write-Host "Run .\run-goose.ps1 to start with the new model"
} else {
    Write-Host "Invalid selection" -ForegroundColor Red
}
