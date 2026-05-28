# PowerShell MySQL 8 Silent Installer
# Extracts MySQL 8 Zip, configures service, initializes database with root password, and starts service.

param(
    [string]$MySQLPort = "3306",
    [string]$MySQLPassword = "root123"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [MYSQL] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

# Check if MySQL service is already registered
$MySQLService = Get-Service -Name "MySQL80" -ErrorAction SilentlyContinue
if (-not $MySQLService) {
    $MySQLService = Get-Service -Name "MySQL" -ErrorAction SilentlyContinue
}

if ($MySQLService) {
    Write-Log "MySQL database service ($($MySQLService.Name)) is already registered on this system."
    if ($MySQLService.Status -ne "Running") {
        Write-Log "Starting MySQL database service..."
        Start-Service $MySQLService.Name
    }
    return
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MySQLZip = Resolve-Path "$ScriptDir\..\redist\mysql8.zip"
$TargetDir = "C:\mysql-8.0"

# Clean up target directory if it exists
if (Test-Path $TargetDir) {
    Write-Log "Warning: Directory $TargetDir already exists. Cleaning it before extraction..." "WARN"
    Remove-Item $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Log "Extracting MySQL 8 to $TargetDir..."
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
Expand-Archive -Path $MySQLZip -DestinationPath "C:\mysql_Temp" -Force

# Move the inner mysql folder files directly into C:\mysql-8.0
$InnerFolder = Get-ChildItem "C:\mysql_Temp" -Directory | Select-Object -First 1
if ($InnerFolder) {
    Copy-Item -Path "$($InnerFolder.FullName)\*" -Destination $TargetDir -Recurse -Force
} else {
    Copy-Item -Path "C:\mysql_Temp\*" -Destination $TargetDir -Recurse -Force
}
Remove-Item "C:\mysql_Temp" -Recurse -Force | Out-Null

# Write my.ini configuration file (bind-address=0.0.0.0 for LAN access)
Write-Log "Creating my.ini configuration file with bind-address=0.0.0.0..."
$MyIniContent = @"
[mysqld]
port=$MySQLPort
bind-address=0.0.0.0
basedir="C:/mysql-8.0"
datadir="C:/mysql-8.0/data"
default_authentication_plugin=mysql_native_password
max_connections=200
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-storage-engine=INNODB
ssl=0
"@
$MyIniContent | Out-File -FilePath "$TargetDir\my.ini" -Encoding utf8 -Force

# Initialize MySQL Database
Write-Log "Initializing MySQL database directory silently (insecure mode)..."
$MysqldExe = "$TargetDir\bin\mysqld.exe"
if (-not (Test-Path $MysqldExe)) {
    throw "mysqld.exe not found in bin folder."
}

# Run initialization command
$InitProcess = Start-Process -FilePath $MysqldExe -ArgumentList "--defaults-file=`"$TargetDir\my.ini`" --initialize-insecure --user=mysql" -Wait -NoNewWindow -PassThru
if ($InitProcess.ExitCode -ne 0) {
    throw "MySQL initialization failed with exit code $($InitProcess.ExitCode)."
}
Write-Log "MySQL database directory initialized successfully."

# Install MySQL Service
Write-Log "Installing MySQL 8 as Windows Service..."
$ServiceProcess = Start-Process -FilePath $MysqldExe -ArgumentList "--install MySQL80 --defaults-file=`"$TargetDir\my.ini`"" -Wait -NoNewWindow -PassThru
if ($ServiceProcess.ExitCode -ne 0) {
    throw "Failed to install MySQL service. Exit code $($ServiceProcess.ExitCode)."
}

# Verify service is created
$MySQLService = Get-Service -Name "MySQL80" -ErrorAction SilentlyContinue
if (-not $MySQLService) {
    throw "MySQL80 service was not found after installation attempt."
}

# Set service startup type
Set-Service -Name "MySQL80" -StartupType Automatic
Write-Log "MySQL service startup set to Automatic."

# Start MySQL Service
Write-Log "Starting MySQL service..."
Start-Service MySQL80
Write-Log "MySQL service started successfully."

# Set Root Password
Write-Log "Configuring root account with native password authentication and setting password..."
$MysqlExe = "$TargetDir\bin\mysql.exe"
if (-not (Test-Path $MysqlExe)) {
    throw "mysql.exe CLI client not found."
}

# Wait for service to fully start and listen
Start-Sleep -Seconds 5

# Set password using mysql.exe client
$SqlCmd = "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MySQLPassword'; FLUSH PRIVILEGES;"
$SqlTempFile = "C:\StoreManagementSetupTemp\set_pwd.sql"
if (-not (Test-Path "C:\StoreManagementSetupTemp")) {
    New-Item -ItemType Directory -Path "C:\StoreManagementSetupTemp" -Force | Out-Null
}
$SqlCmd | Out-File -FilePath $SqlTempFile -Encoding utf8 -Force

Write-Log "Applying password configuration to MySQL..."
$SetPwdProcess = Start-Process -FilePath $MysqlExe -ArgumentList "-u root --skip-password --port=$MySQLPort --host=127.0.0.1 -e `"source $SqlTempFile`"" -Wait -NoNewWindow -PassThru
Remove-Item $SqlTempFile -Force -ErrorAction SilentlyContinue

if ($SetPwdProcess.ExitCode -ne 0) {
    Write-Log "Warning: Direct root password set returned non-zero code $($SetPwdProcess.ExitCode). Let's attempt password set with alternative command." "WARN"
    $SqlCmd2 = "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MySQLPassword';"
    $SetPwdProcess2 = Start-Process -FilePath $MysqlExe -ArgumentList "-u root --skip-password --port=$MySQLPort --host=127.0.0.1 -e `"$SqlCmd2`"" -Wait -NoNewWindow -PassThru
    if ($SetPwdProcess2.ExitCode -ne 0) {
        throw "Failed to set root database password. Exit code $($SetPwdProcess2.ExitCode)."
    }
}

Write-Log "MySQL root database credentials configured successfully."
