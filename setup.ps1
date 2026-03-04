# NetWriath Setup Script for Windows
# This script installs the necessary tools for an automated recon framework.

Write-Host "--- Starting NetWriath Setup ---" -ForegroundColor Cyan

# 1. Check/Install Winget tools (Python, Go, Nmap, Git)
$tools = @{
    "Python" = "Python.Python.3";
    "Go"     = "GoLang.Go";
    "Nmap"   = "Insecure.Nmap";
    "Git"    = "Git.Git"
}

foreach ($name in $tools.Keys) {
    $id = $tools[$name]
    Write-Host "Checking for $name..." -NoNewline
    if (Get-Command "$name" -ErrorAction SilentlyContinue) {
        Write-Host " [OK] Already installed." -ForegroundColor Green
    } else {
        Write-Host " [MISSING] Installing via Winget..." -ForegroundColor Yellow
        winget install --id $id --silent --accept-package-agreements --accept-source-agreements
    }
}

# 2. Refresh Path for the current session (if Go was just installed)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 3. Install ProjectDiscovery Tools via Go
Write-Host "Installing specialized recon tools via Go (this may take a minute)..." -ForegroundColor Cyan

$goTools = @(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest",
    "github.com/projectdiscovery/httpx/cmd/httpx@latest",
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest",
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest",
    "github.com/sensepost/gowitness@latest"
)

foreach ($toolPath in $goTools) {
    $toolName = ($toolPath -split "/")[-1].Split("@")[0]
    Write-Host "Installing $toolName..."
    go install $toolPath
}

# 4. Ensure Go bin is in Path
$goBin = "$env:USERPROFILE\go\bin"
if ($env:Path -notlike "*$goBin*") {
    Write-Host "Adding Go bin to User Path..." -ForegroundColor Yellow
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$goBin", "User")
    $env:Path += ";$goBin"
}

Write-Host "`n--- Setup Complete! ---" -ForegroundColor Green
Write-Host "Please RESTART your terminal/PowerShell to ensure all tools are ready." -ForegroundColor Cyan
