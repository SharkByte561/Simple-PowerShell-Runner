# Simple PowerShell Runner Setup Script
# Run this script as Administrator

Write-Host "=== Simple PowerShell Runner Setup ===" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    exit 1
}

# Set execution policy
Write-Host "Setting PowerShell execution policy..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Check Git installation
Write-Host "Checking Git installation..." -ForegroundColor Yellow
try {
    git --version
    Write-Host "✅ Git is installed" -ForegroundColor Green
} catch {
    Write-Host "Installing Git..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget
}

# Create working directory
$workingDir = "C:\GitHub"
Write-Host "Creating working directory: $workingDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $workingDir -Force | Out-Null

# Instructions for manual steps
Write-Host "`n=== Next Steps (Manual) ===" -ForegroundColor Cyan
Write-Host "1. Create a new GitHub repository or fork an existing one" -ForegroundColor White
Write-Host "2. Clone your repository to $workingDir" -ForegroundColor White
Write-Host "3. Copy the .github folder from this directory to your repository" -ForegroundColor White
Write-Host "4. Commit and push the changes" -ForegroundColor White
Write-Host "5. Set up a self-hosted runner (see README for instructions)" -ForegroundColor White

Write-Host "`n=== Repository Commands ===" -ForegroundColor Cyan
Write-Host "cd $workingDir" -ForegroundColor Gray
Write-Host "git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git" -ForegroundColor Gray
Write-Host "cd YOUR_REPO" -ForegroundColor Gray
Write-Host "xcopy `"$PSScriptRoot\.github`" `".github`" /E /I /Y" -ForegroundColor Gray
Write-Host "git add ." -ForegroundColor Gray
Write-Host "git commit -m `"Add PowerShell command execution automation`"" -ForegroundColor Gray
Write-Host "git push origin main" -ForegroundColor Gray

Write-Host "`n✅ Basic setup complete!" -ForegroundColor Green
Write-Host "See README.md for full setup instructions including runner configuration." -ForegroundColor Yellow
