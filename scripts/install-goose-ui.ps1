# Goose Desktop UI Installation - Windows
#
# If blocked by execution policy:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=================================================="
Write-Host "  GOOSE DESKTOP UI INSTALLER (Windows)"
Write-Host "=================================================="
Write-Host ""

# Check if already installed
$gooseExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Goose Desktop" -Recurse -Filter "Goose.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($gooseExe) {
    Write-Host "Goose Desktop UI already installed at: $($gooseExe.FullName)" -ForegroundColor Green
    Write-Host ""
    $reply = Read-Host "Reinstall/Update? [y/N]"
    if ($reply -ne 'y' -and $reply -ne 'Y') {
        Write-Host "Installation cancelled."
        exit 0
    }
}

Write-Host "Downloading Goose Desktop installer..." -ForegroundColor Blue
Write-Host ""

# Get latest release download URL for Windows installer
$ErrorActionPreference = "Continue"
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/aaif-goose/goose/releases/latest" -UseBasicParsing
$ErrorActionPreference = "Stop"

# Windows Desktop app is Goose-win32-x64.zip
$desktopAsset = $release.assets | Where-Object { $_.name -eq "Goose-win32-x64.zip" } | Select-Object -First 1

if (-not $desktopAsset) {
    Write-Host "Could not find Goose-win32-x64.zip in latest release." -ForegroundColor Red
    Write-Host "Available assets:"
    $release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
    Write-Host ""
    Write-Host "Try downloading manually from: https://github.com/aaif-goose/goose/releases/latest"
    exit 1
}

$downloadUrl = $desktopAsset.browser_download_url
$sizeMB = [math]::Round($desktopAsset.size / 1MB, 1)
$zipPath = Join-Path $env:TEMP "Goose-win32-x64.zip"

Write-Host "Downloading: Goose-win32-x64.zip ($sizeMB MB)"
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

if (-not (Test-Path $zipPath)) {
    Write-Host "Download failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Installing Goose Desktop UI..."

# Extract to user programs directory
$installDir = Join-Path $env:LOCALAPPDATA "Programs\Goose Desktop"
if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $env:TEMP\goose-desktop-extract -Force

# The zip may contain a top-level folder - flatten if needed
$extracted = Get-ChildItem "$env:TEMP\goose-desktop-extract" -Directory | Select-Object -First 1
if ($extracted) {
    Move-Item $extracted.FullName $installDir
} else {
    Move-Item "$env:TEMP\goose-desktop-extract" $installDir
}
Remove-Item "$env:TEMP\goose-desktop-extract" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -ErrorAction SilentlyContinue

# Create Start Menu shortcut
$gooseExePath = Get-ChildItem $installDir -Recurse -Filter "Goose.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($gooseExePath) {
    $shortcutDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    $shortcutPath = Join-Path $shortcutDir "Goose.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $gooseExePath.FullName
    $shortcut.WorkingDirectory = $PROJECT_DIR
    $shortcut.Description = "Goose AI Desktop"
    $shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
}

Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Blue
Write-Host "========================="

# Check for installed Desktop app
$gooseExe = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Goose Desktop" -Recurse -Filter "Goose.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($gooseExe) {
    Write-Host "  OK Desktop binary: $($gooseExe.FullName)" -ForegroundColor Green
} else {
    Write-Host "  !! Desktop binary not found (may need restart)" -ForegroundColor Yellow
}

# Check for Start Menu shortcut
$startMenuShortcut = Get-ChildItem -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "Goose*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($startMenuShortcut) {
    Write-Host "  OK Start Menu shortcut: $($startMenuShortcut.FullName)" -ForegroundColor Green
} else {
    Write-Host "  INFO No Start Menu shortcut found" -ForegroundColor Blue
}

Write-Host ""
Write-Host "=================================================="
Write-Host "  GOOSE DESKTOP UI INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "=================================================="
Write-Host ""
Write-Host "How to Use:"
Write-Host ""
Write-Host "  1. Launch from Start Menu: search for 'Goose'"
Write-Host "  2. Launch from terminal:   .\run-goose.ps1 (CLI)"
Write-Host ""
Write-Host "Both versions share the same configuration:"
Write-Host "  Config:   $env:USERPROFILE\.config\goose\config.yaml"
Write-Host "  Skills:   $PROJECT_DIR\.agents\skills\"
Write-Host ""
