# PowerShell Master Setup Script for Store Management System
# Coordinates the silent installations and configurations of Java, Tomcat, MySQL, Maven, database tables, and firewall.

param(
    [string]$MySQLPassword = "root123",
    [string]$MySQLPort = "3306",
    [string]$DBName = "store_db",
    [string]$DomainName = "bsietstore.local",
    [string]$TomcatPort = "80",
    [string]$StaticIP = "",
    [string]$SubnetMask = "",
    [string]$Gateway = "",
    [string]$DNS = ""
)

$ErrorActionPreference = "Stop"
$LogFile = "C:\StoreManagementWebApp_setup.log"

# Clean up previous log if exists
if (Test-Path $LogFile) { Remove-Item $LogFile -Force }

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogLine = "[$Timestamp] [%Level%] $Message"
    $LogLine | Out-File -FilePath $LogFile -Append
    
    switch ($Level) {
        "INFO"  { Write-Host $LogLine -ForegroundColor Cyan }
        "WARN"  { Write-Host $LogLine -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogLine -ForegroundColor Red }
        "SUCCESS" { Write-Host $LogLine -ForegroundColor Green }
    }
}

Write-Log "=================================================================="
Write-Log "STARTING AUTOMATED STORE MANAGEMENT SERVER DEPLOYMENT"
Write-Log "=================================================================="
Write-Log "Parameters Received:"
Write-Log "  - MySQL Password: [PROTECTED]"
Write-Log "  - MySQL Port: $MySQLPort"
Write-Log "  - DB Name: $DBName"
Write-Log "  - Domain Name: $DomainName"
Write-Log "  - Tomcat Port: $TomcatPort"
Write-Log "  - Static IP: $StaticIP (Mask: $SubnetMask, Gateway: $Gateway, DNS: $DNS)"

try {
    # Check Administrative privileges
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Installer must be run as Administrator."
    }

    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $WorkDir = Resolve-Path "$ScriptDir\.."

    # 1. Option: Configure Static IP Address (Step 1 of guide)
    if ([string]::IsNullOrWhiteSpace($StaticIP) -eq $false) {
        Write-Log "Step 1/19: Configuring Static IP address to $StaticIP..."
        & "$ScriptDir\configure_static_ip.ps1" -IPAddress $StaticIP -SubnetMask $SubnetMask -Gateway $Gateway -DNS $DNS
    } else {
        Write-Log "Step 1/19: Skipping Static IP configuration (no IP provided)..."
    }

    # 2. Download dependencies
    Write-Log "Step 2/19: Checking and downloading server dependencies..."
    & "$ScriptDir\download_dependencies.ps1"
    
    # 3. Install JDK 17
    Write-Log "Step 3/19: Installing Java JDK 17..."
    & "$ScriptDir\install_jdk.ps1"
    
    # 4. Install Tomcat 9
    Write-Log "Step 4/19: Installing Apache Tomcat 9 on Port $TomcatPort..."
    & "$ScriptDir\install_tomcat.ps1" -TomcatPort $TomcatPort
    
    # 5. Install & Configure MySQL 8
    Write-Log "Step 5/19: Installing and configuring MySQL Server 8 (LAN enabled)..."
    & "$ScriptDir\install_mysql.ps1" -MySQLPort $MySQLPort -MySQLPassword $MySQLPassword
    
    # 6. Create database & Seed + LAN database user
    Write-Log "Step 6/19: Configuring Database, importing schema, and setting up storeuser..."
    & "$ScriptDir\setup_database.ps1" -MySQLPort $MySQLPort -MySQLPassword $MySQLPassword -DBName $DBName -WorkDir $WorkDir
    
    # 7. Configure DBConnection.java, Build project via Maven, and deploy WAR
    Write-Log "Step 7/19: Modifying configuration files, compiling and deploying web application as ROOT.war..."
    & "$ScriptDir\deploy_war.ps1" -MySQLPort $MySQLPort -MySQLPassword $MySQLPassword -DBName $DBName -WorkDir $WorkDir
    
    # 8. Configure Firewall
    Write-Log "Step 8/19: Configuring Windows Firewall rules for Ports $TomcatPort, 8080, and $MySQLPort..."
    & "$ScriptDir\configure_firewall.ps1" -TomcatPort $TomcatPort -MySQLPort $MySQLPort
    
    # 9. Configure Domain Hosts
    Write-Log "Step 9/19: Setting up local domain hosts file entries..."
    & "$ScriptDir\configure_hosts.ps1" -DomainName $DomainName
    
    # 10. Verify deployment
    Write-Log "Step 10/19: Running local deployment validation tests..."
    & "$ScriptDir\verify_server.ps1" -TomcatPort $TomcatPort -DomainName $DomainName

    Write-Log "==================================================================" SUCCESS
    Write-Log "SERVER INSTALLATION AND DEPLOYMENT COMPLETED SUCCESSFULLY!" SUCCESS
    Write-Log "==================================================================" SUCCESS
    
    if ($TomcatPort -eq "80") {
        Write-Log "Access application locally: http://localhost" SUCCESS
        Write-Log "Access application via Local Domain: http://$DomainName" SUCCESS
    } else {
        Write-Log "Access application locally: http://localhost:$TomcatPort" SUCCESS
        Write-Log "Access application via Local Domain: http://$($DomainName):$TomcatPort" SUCCESS
    }
    
    # Get server IP addresses
    $IPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -ExpandProperty IPAddress
    foreach ($IP in $IPs) {
        if ($TomcatPort -eq "80") {
            Write-Log "Access application via LAN IP: http://$IP" SUCCESS
        } else {
            Write-Log "Access application via LAN IP: http://$IP`:$TomcatPort" SUCCESS
        }
    }
    Write-Log "Check installation log for detailed output: $LogFile" SUCCESS

} catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR"
    Write-Log "Installation failed. Please review the log file at: $LogFile" "ERROR"
    exit 1
}
