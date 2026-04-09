# Brave Search Setup for Goose AI - Windows
#
# If blocked by execution policy:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $PROJECT_DIR

Write-Host "============================================"
Write-Host "Brave Search Setup for Goose AI"
Write-Host "============================================"
Write-Host ""
Write-Host "Get your free API key from: https://brave.com/search/api/"
Write-Host "Free tier: 2,000 queries/month"
Write-Host ""

$apiKey = Read-Host "Enter your Brave Search API key"
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "Error: API key cannot be empty" -ForegroundColor Red
    exit 1
}

# Store API key in .env file
Write-Host "Creating .env file..."
$envPath = Join-Path $PROJECT_DIR "brave-search-mcp\.env"
"BRAVE_API_KEY=$apiKey" | Set-Content $envPath
Write-Host "  OK Saved to $envPath" -ForegroundColor Green

# Add Brave Search extension to Goose CLI config
$configPath = Join-Path $env:USERPROFILE ".config\goose\config.yaml"
if (Test-Path $configPath) {
    $configContent = Get-Content $configPath -Raw
    if ($configContent -match "brave-search:") {
        Write-Host "  OK Brave Search already in Goose config" -ForegroundColor Green
    } else {
        # Insert before GOOSE_TELEMETRY_ENABLED (or append to extensions)
        $extension = @"

  brave-search:
    name: brave-search
    cmd: npx
    args:
      - -y
      - "@brave/brave-search-mcp-server"
    enabled: true
    envs:
      BRAVE_API_KEY: "$apiKey"
    type: stdio
    timeout: 300
"@
        if ($configContent -match "GOOSE_TELEMETRY_ENABLED:") {
            $configContent = $configContent -replace "(GOOSE_TELEMETRY_ENABLED:)", "$extension`n`$1"
        } else {
            $configContent += $extension
        }
        Set-Content $configPath $configContent -NoNewline
        Write-Host "  OK Added Brave Search to Goose config" -ForegroundColor Green
    }
} else {
    Write-Host "  INFO Goose config not found at $configPath - run setup.ps1 first" -ForegroundColor Yellow
}

# Test API
Write-Host ""
Write-Host "Testing Brave Search API..."
$ErrorActionPreference = "Continue"
try {
    $headers = @{ "X-Subscription-Token" = $apiKey; "Accept" = "application/json" }
    $response = Invoke-WebRequest -Uri "https://api.search.brave.com/res/v1/web/search?q=test&count=1" -Headers $headers -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "  OK Brave Search API is working!" -ForegroundColor Green
    } else {
        Write-Host "  !! API returned status $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  FAIL API test failed: $($_.Exception.Message)" -ForegroundColor Red
}
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================"
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "============================================"
Write-Host ""
Write-Host "For CLI: restart Goose with .\run-goose.ps1"
Write-Host ""
Write-Host "For Desktop UI: add the extension manually in Settings > Extensions:"
Write-Host "  Name:    brave-search"
Write-Host "  Type:    STDIO"
Write-Host "  Command: npx -y @brave/brave-search-mcp-server"
Write-Host "  Env:     BRAVE_API_KEY = $apiKey"
Write-Host ""
Write-Host "Examples:"
Write-Host "  'Search the web for React best practices'"
Write-Host "  'Find news about artificial intelligence'"
