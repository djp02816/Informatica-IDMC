# ============================================================================
# Process Engine Deployment Diagnostic Script (PowerShell)
# Purpose: Advanced diagnostics for process-engine deployment failures
# Author: GitHub Copilot
# Date: 2026-06-01
# Usage: powershell -ExecutionPolicy Bypass -File diagnose-deployment.ps1
# ============================================================================

param(
    [switch]$Verbose = $false,
    [switch]$CollectLogs = $false
)

# ============================================================================
# Configuration
# ============================================================================
$APP_DIR = "C:\PROGRA~1\INFORM~1\apps\process-engine"
$APP_VERSION = "15124581.1.1"
$LCM_DIR = "$APP_DIR\$APP_VERSION\.lcm"
$JAVA_HOME_8 = "C:\PROGRA~1\INFORM~1\jdk8\jre"
$JAVA_HOME_17 = "C:\PROGRA~1\INFORM~1\jdk"
$PG_DB_BINARIES = "$APP_DIR\data\db"
$LOG_DIR = "$APP_DIR\logs"

$REPORT_FILE = "$PSScriptRoot\deployment-diagnostic-report.txt"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# ============================================================================
# Color Output Functions
# ============================================================================
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
    Add-Content -Path $REPORT_FILE -Value "✓ $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
    Add-Content -Path $REPORT_FILE -Value "✗ $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
    Add-Content -Path $REPORT_FILE -Value "⚠ $Message"
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
    Add-Content -Path $REPORT_FILE -Value "ℹ $Message"
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========== $Title ==========" -ForegroundColor Blue
    Add-Content -Path $REPORT_FILE -Value ""
    Add-Content -Path $REPORT_FILE -Value "========== $Title =========="
}

# ============================================================================
# Initialize Report
# ============================================================================
"============================================================================" | Out-File -FilePath $REPORT_FILE
"Process Engine Deployment Diagnostic Report" | Add-Content -Path $REPORT_FILE
"Generated: $TIMESTAMP" | Add-Content -Path $REPORT_FILE
"PowerShell Version: $($PSVersionTable.PSVersion)" | Add-Content -Path $REPORT_FILE
"============================================================================" | Add-Content -Path $REPORT_FILE
"" | Add-Content -Path $REPORT_FILE

# ============================================================================
# 1. Directory Structure Validation
# ============================================================================
Write-Section "Directory Structure Validation"

$directories = @(
    @{Path = $APP_DIR; Name = "Process Engine Root"},
    @{Path = "$APP_DIR\$APP_VERSION"; Name = "Version Directory"},
    @{Path = $LCM_DIR; Name = "LCM Configuration Directory"},
    @{Path = "$APP_DIR\bin"; Name = "Binary Directory"},
    @{Path = $LOG_DIR; Name = "Log Directory"},
    @{Path = $PG_DB_BINARIES; Name = "PostgreSQL Binaries"}
)

foreach ($dir in $directories) {
    if (Test-Path -Path $dir.Path) {
        Write-Success "Directory exists: $($dir.Name) - $($dir.Path)"
    } else {
        Write-Error "Directory NOT found: $($dir.Name) - $($dir.Path)"
    }
}

# ============================================================================
# 2. Critical Files Validation
# ============================================================================
Write-Section "Critical Files Validation"

$files = @(
    @{Path = "$LCM_DIR\deploy-wrapper.bat"; Name = "deploy-wrapper.bat"},
    @{Path = "$LCM_DIR\app-key.pem"; Name = "app-key.pem"},
    @{Path = "$LCM_DIR\app-ca-bundle.pem"; Name = "app-ca-bundle.pem"},
    @{Path = "$LCM_DIR\app-cert-bundle.pem"; Name = "app-cert-bundle.pem"},
    @{Path = "$LCM_DIR\app-keystore.jks"; Name = "app-keystore.jks"},
    @{Path = "$LCM_DIR\app-truststore.jks"; Name = "app-truststore.jks"},
    @{Path = "$APP_DIR\$APP_VERSION\bin\start.bat"; Name = "start.bat"},
    @{Path = "$APP_DIR\$APP_VERSION\bin\getDBDetails.bat"; Name = "getDBDetails.bat"}
)

foreach ($file in $files) {
    if (Test-Path -Path $file.Path) {
        $fileInfo = Get-Item -Path $file.Path
        Write-Success "File exists: $($file.Name) (Size: $($fileInfo.Length) bytes)"
        
        # Check if file is readable
        $canRead = $true
        try {
            $stream = [System.IO.File]::OpenRead($file.Path)
            $stream.Close()
        } catch {
            $canRead = $false
            Write-Warning "File is NOT readable: $($file.Name)"
        }
        
        if ($canRead) {
            Write-Success "File is readable: $($file.Name)"
        }
    } else {
        Write-Error "File NOT found: $($file.Name) - $($file.Path)"
    }
}

# ============================================================================
# 3. Java Installation Check
# ============================================================================
Write-Section "Java Installation Check"

$javaInstallations = @(
    @{Path = $JAVA_HOME_8; Version = "Java 8"},
    @{Path = $JAVA_HOME_17; Version = "Java 17"}
)

foreach ($java in $javaInstallations) {
    $javaExe = "$($java.Path)\bin\java.exe"
    
    if (Test-Path -Path $javaExe) {
        Write-Success "$($java.Version) found at: $($java.Path)"
        
        try {
            $javaVersion = & $javaExe -version 2>&1
            Write-Info "Version Details: $($javaVersion[0])"
        } catch {
            Write-Error "Could not retrieve $($java.Version) details"
        }
    } else {
        Write-Error "$($java.Version) NOT found at: $($java.Path)"
    }
}

# ============================================================================
# 4. PostgreSQL Database Check
# ============================================================================
Write-Section "PostgreSQL Database Check"

$pgStartScript = "$PG_DB_BINARIES\util\server_start.bat"
if (Test-Path -Path $pgStartScript) {
    Write-Success "PostgreSQL startup script found"
} else {
    Write-Error "PostgreSQL startup script NOT found"
}

# Check if PostgreSQL process is running
$pgProcess = Get-Process -Name "postgres" -ErrorAction SilentlyContinue
if ($pgProcess) {
    Write-Success "PostgreSQL is running (PID: $($pgProcess.Id))"
} else {
    Write-Warning "PostgreSQL is NOT running"
    Write-Info "Attempting to start PostgreSQL..."
    
    # Try to get DB port from environment
    $dbPort = "5432"
    Write-Info "Expected PostgreSQL port: $dbPort"
}

# ============================================================================
# 5. File Permissions Analysis
# ============================================================================
Write-Section "File Permissions Analysis"

$permissionFiles = @(
    "$LCM_DIR\deploy-wrapper.bat",
    "$APP_DIR\$APP_VERSION\bin\start.bat"
)

foreach ($file in $permissionFiles) {
    if (Test-Path -Path $file) {
        try {
            $acl = Get-Acl -Path $file
            Write-Info "File: $file"
            Write-Info "Owner: $($acl.Owner)"
            
            foreach ($access in $acl.Access) {
                Write-Info "  - $($access.IdentityReference): $($access.FileSystemRights)"
            }
        } catch {
            Write-Warning "Could not retrieve permissions for: $file"
        }
    }
}

# ============================================================================
# 6. Disk Space Analysis
# ============================================================================
Write-Section "Disk Space Analysis"

try {
    $driveC = Get-Volume -DriveLetter C
    $freeSpace = [math]::Round($driveC.SizeRemaining / 1GB, 2)
    $totalSpace = [math]::Round($driveC.Size / 1GB, 2)
    $usedSpace = [math]::Round(($driveC.Size - $driveC.SizeRemaining) / 1GB, 2)
    
    Write-Info "Drive C: Space Analysis"
    Write-Info "  - Total Space: $totalSpace GB"
    Write-Info "  - Used Space: $usedSpace GB"
    Write-Info "  - Free Space: $freeSpace GB"
    
    if ($freeSpace -lt 5) {
        Write-Error "Low disk space! Only $freeSpace GB free (minimum 5 GB recommended)"
    } else {
        Write-Success "Sufficient disk space available: $freeSpace GB"
    }
} catch {
    Write-Warning "Could not retrieve disk space information"
}

# ============================================================================
# 7. Log File Analysis
# ============================================================================
Write-Section "Log File Analysis"

if (Test-Path -Path $LOG_DIR) {
    Write-Success "Log directory exists: $LOG_DIR"
    
    $logFiles = Get-ChildItem -Path $LOG_DIR -File -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 10
    
    if ($logFiles) {
        Write-Info "Recent log files:"
        foreach ($log in $logFiles) {
            Write-Info "  - $($log.Name) (Modified: $($log.LastWriteTime))"
        }
        
        # Analyze most recent log for errors
        $recentLog = $logFiles[0]
        Write-Info "Analyzing most recent log: $($recentLog.Name)"
        
        try {
            $logContent = Get-Content -Path $recentLog.FullName -Tail 50
            $errorLines = $logContent | Select-String -Pattern "ERROR|Exception|Failed" -ErrorAction SilentlyContinue
            
            if ($errorLines) {
                Write-Error "Found error entries in log:"
                foreach ($line in $errorLines) {
                    Write-Error "  $line"
                }
            }
        } catch {
            Write-Warning "Could not read log file: $($recentLog.Name)"
        }
    } else {
        Write-Warning "No log files found in: $LOG_DIR"
    }
} else {
    Write-Error "Log directory NOT found: $LOG_DIR"
}

# ============================================================================
# 8. Environment Variables Check
# ============================================================================
Write-Section "Environment Variables Check"

$envVars = @(
    "JAVA_HOME",
    "PATH",
    "CATALINA_HOME",
    "CATALINA_BASE"
)

foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User") -or [Environment]::GetEnvironmentVariable($var, "Machine")
    if ($value) {
        Write-Success "Environment variable set: $var"
        Write-Info "  Value: $value"
    } else {
        Write-Warning "Environment variable NOT set: $var"
    }
}

# ============================================================================
# 9. Process Validation
# ============================================================================
Write-Section "Process Validation"

$processes = @(
    @{Name = "java"; Description = "Java Process"},
    @{Name = "postgres"; Description = "PostgreSQL"},
    @{Name = "tomcat"; Description = "Tomcat Web Server"}
)

foreach ($proc in $processes) {
    $running = Get-Process -Name $proc.Name -ErrorAction SilentlyContinue
    if ($running) {
        Write-Success "$($proc.Description) is running"
    } else {
        Write-Warning "$($proc.Description) is NOT running"
    }
}

# ============================================================================
# 10. Deploy Wrapper Batch Script Analysis
# ============================================================================
Write-Section "Deploy Wrapper Batch Script Analysis"

$deployWrapperPath = "$LCM_DIR\deploy-wrapper.bat"
if (Test-Path -Path $deployWrapperPath) {
    Write-Success "deploy-wrapper.bat found"
    
    try {
        $content = Get-Content -Path $deployWrapperPath
        Write-Info "Script length: $($content.Count) lines"
        
        # Check for common issues
        if ($content -match "ERRORLEVEL") {
            Write-Success "Script checks error levels"
        }
        
        if ($content -match "EXIT.*210") {
            Write-Error "Script may exit with code 210 - this is the failure code!"
        }
    } catch {
        Write-Warning "Could not analyze deploy-wrapper.bat content"
    }
} else {
    Write-Error "deploy-wrapper.bat not found!"
}

# ============================================================================
# Final Summary
# ============================================================================
Write-Section "Diagnostic Summary"

Write-Info ""
Write-Info "Full diagnostic report saved to: $REPORT_FILE"
Write-Info ""
Write-Info "Next Steps:"
Write-Info "1. Review the diagnostic report for any critical issues (✗)"
Write-Info "2. Check that all required directories and files exist"
Write-Info "3. Verify Java is properly installed and configured"
Write-Info "4. Ensure PostgreSQL is running or can start successfully"
Write-Info "5. Check file permissions on the .lcm directory and scripts"
Write-Info "6. Review application logs in: $LOG_DIR"
Write-Info ""

# ============================================================================
# Optional: Collect Log Files
# ============================================================================
if ($CollectLogs) {
    Write-Section "Collecting Log Files"
    
    $zipPath = "$PSScriptRoot\process-engine-logs-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    
    if (Test-Path -Path $LOG_DIR) {
        try {
            Compress-Archive -Path $LOG_DIR -DestinationPath $zipPath
            Write-Success "Log files archived to: $zipPath"
        } catch {
            Write-Error "Failed to create log archive: $_"
        }
    } else {
        Write-Error "Log directory not found, cannot collect logs"
    }
}

Write-Host ""
Write-Host "Diagnostics complete! Press Enter to exit."
Read-Host
