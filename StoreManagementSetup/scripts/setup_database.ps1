# PowerShell Database Installer
# Creates store_db database, executes the schema setup script, and configures the LAN user.

param(
    [string]$MySQLPort = "3306",
    [string]$MySQLPassword = "root123",
    [string]$DBName = "store_db",
    [string]$WorkDir = ""
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [DATABASE_SETUP] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Determine mysql.exe location
$MysqlExe = "C:\mysql-8.0\bin\mysql.exe"
if (-not (Test-Path $MysqlExe)) {
    $whereMysql = Get-Command mysql -ErrorAction SilentlyContinue
    if ($whereMysql) {
        $MysqlExe = $whereMysql.Source
    } else {
        $standardPaths = Get-ChildItem "C:\Program Files\MySQL\MySQL Server *" -Filter mysql.exe -Recurse -ErrorAction SilentlyContinue
        if ($standardPaths) {
            $MysqlExe = $standardPaths[0].FullName
        } else {
            throw "mysql.exe CLI client could not be located."
        }
    }
}

Write-Log "Using mysql client: $MysqlExe"

# Locate the SQL script
$SqlScriptPath = "$ScriptDir\..\sql\reset_store_db_transfer_scrap.sql"
if (-not (Test-Path $SqlScriptPath)) {
    if ($WorkDir -and (Test-Path "$WorkDir\StoreManagementWebApp\database\reset_store_db_transfer_scrap.sql")) {
        $SqlScriptPath = "$WorkDir\StoreManagementWebApp\database\reset_store_db_transfer_scrap.sql"
    } else {
        throw "Database SQL script not found at $SqlScriptPath."
    }
}

Write-Log "Found SQL script to execute: $SqlScriptPath"

# Run command to check connection and create database
Write-Log "Creating database '$DBName' if it does not exist..."
$CreateDbCmd = "CREATE DATABASE IF NOT EXISTS $DBName CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
$DbProcess = Start-Process -FilePath $MysqlExe -ArgumentList "-u root -p`"$MySQLPassword`" --port=$MySQLPort --host=127.0.0.1 -e `"$CreateDbCmd`"" -Wait -NoNewWindow -PassThru
if ($DbProcess.ExitCode -ne 0) {
    throw "Failed to connect to MySQL database server to create database. Verify credentials."
}

# Run the SQL script to seed tables and initial records
Write-Log "Importing SQL file tables and configuration data into '$DBName'..."
$ImportProcess = Start-Process -FilePath $MysqlExe -ArgumentList "-u root -p`"$MySQLPassword`" --port=$MySQLPort --host=127.0.0.1 --database=$DBName -e `"source $SqlScriptPath`"" -Wait -NoNewWindow -PassThru
if ($ImportProcess.ExitCode -ne 0) {
    throw "Database table creation and data seed script failed. Exit code $($ImportProcess.ExitCode)."
}

# Step 3: Create LAN Database User and Grant Privileges
Write-Log "Creating LAN database user 'storeuser' and granting privileges..."
$LanUserSql = "CREATE USER IF NOT EXISTS 'storeuser'@'%' IDENTIFIED BY 'store123'; GRANT ALL PRIVILEGES ON $DBName.* TO 'storeuser'@'%'; FLUSH PRIVILEGES;"
$LanUserProcess = Start-Process -FilePath $MysqlExe -ArgumentList "-u root -p`"$MySQLPassword`" --port=$MySQLPort --host=127.0.0.1 -e `"$LanUserSql`"" -Wait -NoNewWindow -PassThru
if ($LanUserProcess.ExitCode -ne 0) {
    Write-Log "Warning: Setting up LAN database user returned non-zero code $($LanUserProcess.ExitCode)." "WARN"
} else {
    Write-Log "LAN Database user 'storeuser' configured successfully."
}

Write-Log "Database '$DBName' successfully initialized and seeded with default settings."
