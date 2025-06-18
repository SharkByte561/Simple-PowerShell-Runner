# Complete GitHub Actions Runner Setup Script - WINDOWS VERSION with NSSM
# Run this script as Administrator

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken = "",
    
    [Parameter(Mandatory=$false)]
    [string]$RepoUrl = "https://github.com/SharkByte561/Simple-PowerShell-Runner",
    
    [Parameter(Mandatory=$false)]
    [string]$RunnerName = "windows-powershell-runner",
    
    [Parameter(Mandatory=$false)]
    [string]$RunnerLabels = "self-hosted,windows,powershell"
)

Write-Host "=== GitHub Actions Runner Complete Setup (WINDOWS + NSSM) ===" -ForegroundColor Green

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    exit 1
}

try {
    Write-Host "Step 1: Installing/Verifying Chocolatey..." -ForegroundColor Yellow
    $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $chocoInstalled) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "Chocolatey installed successfully" -ForegroundColor Green
    } else {
        Write-Host "Chocolatey already installed" -ForegroundColor Green
    }

    Write-Host "Step 2: Installing NSSM (Non-Sucking Service Manager)..." -ForegroundColor Yellow
    $nssmInstalled = Get-Command nssm -ErrorAction SilentlyContinue
    if (-not $nssmInstalled) {
        Write-Host "Installing NSSM via Chocolatey..." -ForegroundColor Cyan
        choco install nssm -y
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "NSSM installed successfully" -ForegroundColor Green
    } else {
        Write-Host "NSSM already installed" -ForegroundColor Green
    }

    Write-Host "Step 3: Creating actions-runner directory..." -ForegroundColor Yellow
    $runnerPath = "C:\actions-runner"
    New-Item -ItemType Directory -Path $runnerPath -Force | Out-Null
    Set-Location $runnerPath
    Write-Host "Created directory: $runnerPath" -ForegroundColor Green

    Write-Host "Step 4: Downloading GitHub Actions runner..." -ForegroundColor Yellow
    $runnerUrl = "https://github.com/actions/runner/releases/download/v2.325.0/actions-runner-win-x64-2.325.0.zip"
    $runnerZip = "actions-runner-win-x64-2.325.0.zip"
    
    if (-not (Test-Path $runnerZip)) {
        Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip -UseBasicParsing
        Write-Host "Downloaded runner package" -ForegroundColor Green
    } else {
        Write-Host "Runner package already exists" -ForegroundColor Green
    }

    Write-Host "Step 5: Validating download integrity..." -ForegroundColor Yellow
    $expectedHash = '8601aa56828c084b29bdfda574af1fcde0943ce275fdbafb3e6d4a8611245b1b'
    $actualHash = (Get-FileHash -Path $runnerZip -Algorithm SHA256).Hash
    
    if ($actualHash.ToUpper() -ne $expectedHash.ToUpper()) {
        throw "Computed checksum did not match expected hash. Download may be corrupted."
    }
    Write-Host "Hash validation passed" -ForegroundColor Green

    Write-Host "Step 6: Extracting runner package..." -ForegroundColor Yellow
    if (-not (Test-Path "config.cmd")) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/$runnerZip", "$PWD")
        Remove-Item $runnerZip -Force
        Write-Host "Runner extracted successfully" -ForegroundColor Green
    } else {
        Write-Host "Runner already extracted" -ForegroundColor Green
    }

    Write-Host "Step 7: Configuring the runner..." -ForegroundColor Yellow
    Write-Host "Repository: $RepoUrl" -ForegroundColor Cyan
    Write-Host "Token: $($GitHubToken.Substring(0,8))..." -ForegroundColor Cyan
    Write-Host "Runner Name: $RunnerName" -ForegroundColor Cyan
    Write-Host "Labels: $RunnerLabels" -ForegroundColor Cyan

    $configArgs = @(
        "--url", $RepoUrl,
        "--token", $GitHubToken,
        "--name", $RunnerName,
        "--labels", $RunnerLabels,
        "--work", "_work",
        "--unattended",
        "--replace"
    )
    & .\config.cmd @configArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Runner configuration failed with exit code: $LASTEXITCODE"
    }
    Write-Host "Runner configured successfully" -ForegroundColor Green

    Write-Host "Step 8: Cleaning up any existing services..." -ForegroundColor Yellow
    $serviceName = "GitHubActionsRunner"
    $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Host "Removing existing service..." -ForegroundColor Cyan
        nssm stop $serviceName
        nssm remove $serviceName confirm
        Write-Host "Existing service removed" -ForegroundColor Green
    }

    Write-Host "Step 9: Installing runner as Windows service using NSSM..." -ForegroundColor Yellow
    $runnerExe = "$runnerPath\run.cmd"
    nssm install $serviceName $runnerExe
    nssm set $serviceName Application $runnerExe
    nssm set $serviceName AppDirectory $runnerPath
    nssm set $serviceName DisplayName "GitHub Actions Runner ($RunnerName)"
    nssm set $serviceName Description "GitHub Actions self-hosted runner for PowerShell automation"
    nssm set $serviceName Start SERVICE_AUTO_START
    nssm set $serviceName ObjectName LocalSystem
    nssm set $serviceName AppStdout "$runnerPath\logs\service-output.log"
    nssm set $serviceName AppStderr "$runnerPath\logs\service-error.log"
    nssm set $serviceName AppRotateFiles 1
    nssm set $serviceName AppRotateOnline 1
    nssm set $serviceName AppRotateSeconds 86400
    nssm set $serviceName AppRotateBytes 1048576
    New-Item -ItemType Directory -Path "$runnerPath\logs" -Force | Out-Null
    Write-Host "Service installed successfully using NSSM" -ForegroundColor Green

    Write-Host "Step 10: Starting the GitHub Actions Runner service..." -ForegroundColor Yellow
    nssm start $serviceName
    Start-Sleep -Seconds 5
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Host "Service started successfully!" -ForegroundColor Green
    } else {
        Write-Warning "Service may not have started properly. Checking status..."
        nssm status $serviceName
    }

    Write-Host "Step 11: Verifying runner connectivity..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    if (Test-Path ".runner") {
        $runnerConfig = Get-Content ".runner" | ConvertFrom-Json
        Write-Host "Runner configuration file found" -ForegroundColor Green
        Write-Host "Runner ID: $($runnerConfig.agentId)" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "GITHUB ACTIONS RUNNER SETUP COMPLETE!" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Runner Details:" -ForegroundColor Cyan
    Write-Host "Location: $runnerPath" -ForegroundColor White
    Write-Host "Name: $RunnerName" -ForegroundColor White
    Write-Host "Repository: $RepoUrl" -ForegroundColor White
    Write-Host "Status: Running as Windows Service (via NSSM)" -ForegroundColor White
    Write-Host "Service Name: $serviceName" -ForegroundColor White
    Write-Host ""
    Write-Host "Installed Components:" -ForegroundColor Cyan
    Write-Host "Chocolatey package manager" -ForegroundColor White
    Write-Host "NSSM (Non-Sucking Service Manager)" -ForegroundColor White
    Write-Host "GitHub Actions Runner" -ForegroundColor White
    Write-Host "Windows Service (auto-start)" -ForegroundColor White
    Write-Host ""
    Write-Host "Verification Steps:" -ForegroundColor Cyan
    Write-Host "1. Check your repository on GitHub:" -ForegroundColor White
    Write-Host "   Go to: $RepoUrl/settings/actions/runners" -ForegroundColor Gray
    Write-Host "2. You should see '$RunnerName' listed as 'Idle'" -ForegroundColor White
    Write-Host "3. If not visible, wait 1-2 minutes and refresh the page" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage in Workflows:" -ForegroundColor Cyan
    Write-Host "runs-on: self-hosted" -ForegroundColor Gray
    Write-Host "runs-on: [self-hosted, windows, powershell]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Service Management Commands:" -ForegroundColor Cyan
    Write-Host "Check status: nssm status $serviceName" -ForegroundColor Gray
    Write-Host "Stop service: nssm stop $serviceName" -ForegroundColor Gray
    Write-Host "Start service: nssm start $serviceName" -ForegroundColor Gray
    Write-Host "Restart service: nssm restart $serviceName" -ForegroundColor Gray
    Write-Host "Remove service: nssm remove $serviceName confirm" -ForegroundColor Gray
    Write-Host "View logs: Get-Content '$runnerPath\logs\service-output.log' -Tail 50" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Alternative Commands:" -ForegroundColor Cyan
    Write-Host "PowerShell: Get-Service -Name '$serviceName'" -ForegroundColor Gray
    Write-Host "Windows: services.msc (look for 'GitHub Actions Runner')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Your runner is ready! Go create an issue to test it." -ForegroundColor Green
    Write-Host "Create an issue at: $RepoUrl/issues/new/choose" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Testing Command:" -ForegroundColor Cyan
    Write-Host "Create a PowerShell issue with command: Get-ComputerInfo | Select-Object WindowsVersion" -ForegroundColor Gray

} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure you are running as Administrator" -ForegroundColor White
    Write-Host "2. Check your internet connection" -ForegroundColor White
    Write-Host "3. Verify the GitHub token is valid and not expired" -ForegroundColor White
    Write-Host "4. Make sure the repository URL is correct" -ForegroundColor White
    Write-Host "5. Try running manually by navigating to C:\actions-runner and running .\run.cmd" -ForegroundColor White
    Write-Host ""
    Write-Host "Manual Service Commands (if needed):" -ForegroundColor Yellow
    Write-Host "nssm install GitHubActionsRunner C:\actions-runner\run.cmd" -ForegroundColor Gray
    Write-Host "nssm set GitHubActionsRunner AppDirectory C:\actions-runner" -ForegroundColor Gray
    Write-Host "nssm start GitHubActionsRunner" -ForegroundColor Gray
    exit 1
}
