# Simple PowerShell Runner

A basic GitHub automation system that executes PowerShell commands from GitHub Issues.

## 🚀 What It Does

1. **Create an Issue** with a PowerShell command
2. **GitHub Actions** automatically detects and runs the command
3. **Results are posted** back to the issue as a comment
4. **Issue is closed** if successful

## 📁 Repository Structure

```
├── .github/
│   ├── workflows/
│   │   └── execute-powershell.yml     # Main automation workflow
│   └── ISSUE_TEMPLATE/
│       └── powershell-command.yml     # Issue template for commands
├── setup.ps1                          # Quick setup script
└── README.md                          # This file
```

## ⚡ Quick Setup

### 1. Prerequisites
- Windows machine for self-hosted runner
- GitHub repository
- Administrator access

### 2. Automated Setup
```powershell
# Run as Administrator
.\setup.ps1
```

### 3. Manual Steps
1. **Create/Fork Repository**: Create a new GitHub repo or fork this one
2. **Clone Repository**: 
   ```bash
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
   cd YOUR_REPO
   ```
3. **Copy Files**: Copy the `.github` folder to your repository
4. **Commit Changes**:
   ```bash
   git add .
   git commit -m "Add PowerShell command execution automation"
   git push origin main
   ```

### 4. Set Up Self-Hosted Runner
1. Go to your repository on GitHub
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Follow the instructions to download and configure the runner
5. Make sure to add the label `windows` to your runner

## 🔧 How to Use

### Step 1: Create an Issue
1. Go to your repository's **Issues** tab
2. Click **New Issue**
3. Select **Execute PowerShell Command** template
4. Fill in your PowerShell command

### Step 2: Submit and Wait
- The workflow will automatically start
- Check the **Actions** tab to see progress
- Results will be posted as a comment on your issue

## 📝 Example Commands

### Simple Examples
```powershell
# Get system information
Get-ComputerInfo | Select-Object WindowsVersion, TotalPhysicalMemory

# List running processes
Get-Process | Where-Object { $_.CPU -gt 100 } | Select-Object Name, CPU

# Check disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace

# Hello World
Write-Host "Hello from GitHub Actions!" -ForegroundColor Green
```

### More Advanced Examples
```powershell
# Install a program via Chocolatey
choco install notepadplusplus -y

# Get Windows features
Get-WindowsFeature | Where-Object { $_.InstallState -eq "Installed" } | Select-Object Name

# Check services
Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object Name, Status
```

## 🛡️ Safety Features

### Built-in Protections
- **Command validation**: Basic checks for dangerous commands
- **Pattern blocking**: Prevents obviously harmful operations
- **Manual approval**: You control what commands are submitted

### Blocked Patterns
- `rm -rf` or `del /s` (file deletion)
- `format c:` (disk formatting)
- `shutdown` or `restart-computer` (system control)
- Recursive file removal commands

## 🔍 Workflow Details

### When Commands Execute
- Issue is created with `execute-powershell` label
- Command is extracted from issue body
- Safety checks are performed
- Command is executed on self-hosted runner
- Results are posted back to issue

### What You'll See
- ✅ **Success**: Command output posted to issue, issue closed
- ❌ **Failure**: Error message posted, issue remains open
- 📊 **Logs**: Full execution logs available in Actions tab

## 🚀 Runner Setup (Detailed)

### Download and Configure Runner
```powershell
# Create runner directory
New-Item -Path "C:\actions-runner" -ItemType Directory -Force
Set-Location "C:\actions-runner"

# Download runner (get latest URL from GitHub)
Invoke-WebRequest -Uri "RUNNER_DOWNLOAD_URL" -OutFile "actions-runner.zip"
Expand-Archive -Path "actions-runner.zip" -DestinationPath "." -Force

# Configure with your repository
.\config.cmd --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# Install as service
.\svc.sh install
.\svc.sh start
```

### Verify Runner
1. Check service is running: `Get-Service -Name "actions.runner.*"`
2. Verify in GitHub: Settings → Actions → Runners should show your runner as "Idle"

## 📊 Example Issue Templates

### Basic Command
```yaml
PowerShell Command: Get-Process | Select-Object Name, CPU -First 10
Description: List top 10 processes by name and CPU usage
```

### System Check
```yaml
PowerShell Command: |
  Write-Host "System Information:" -ForegroundColor Green
  Get-ComputerInfo | Select-Object WindowsVersion, TotalPhysicalMemory
  Write-Host "Disk Space:" -ForegroundColor Yellow
  Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB,2)}}
Description: Complete system health check
```

## 🛠️ Customization

### Modify the Workflow
Edit `.github/workflows/execute-powershell.yml` to:
- Change runner requirements
- Add more safety checks
- Modify output formatting
- Add additional steps

### Modify the Issue Template
Edit `.github/ISSUE_TEMPLATE/powershell-command.yml` to:
- Add more input fields
- Change validation requirements
- Customize the form layout

## 🔧 Troubleshooting

### Common Issues

**Runner Not Starting**
```powershell
# Check service status
Get-Service -Name "actions.runner.*"

# Restart if needed
Restart-Service -Name "actions.runner.*"
```

**Commands Not Executing**
- Verify issue has `execute-powershell` label
- Check Actions tab for workflow runs
- Review runner logs in `C:\actions-runner\_diag`

**Permission Errors**
- Ensure runner service runs as Administrator
- Check PowerShell execution policy: `Get-ExecutionPolicy`

### Debug Commands
```powershell
# Test PowerShell execution
Get-ExecutionPolicy

# Check runner status
cd C:\actions-runner
.\run.cmd --once

# View recent logs
Get-Content "_diag\Runner_*.log" | Select-Object -Last 50
```

## 🎯 What You'll Learn

This simple automation teaches you:
- **GitHub Actions basics**: Workflows, triggers, jobs
- **Issue templates**: Creating structured user input
- **Self-hosted runners**: Setting up and managing runners
- **PowerShell automation**: Executing scripts remotely
- **GitHub API**: Commenting on issues, adding labels

## 🚀 Next Steps

Once you understand this basic system:
1. **Add more safety checks** for command validation
2. **Create command libraries** with predefined scripts
3. **Add file upload/download** capabilities
4. **Implement approval workflows** for sensitive commands
5. **Scale to the full Chocolatey system** from the main package

## 📜 License

MIT License - Feel free to use and modify as needed.

---

**Ready to get started?** Run `.\setup.ps1` as Administrator and follow the setup steps above! 🚀
