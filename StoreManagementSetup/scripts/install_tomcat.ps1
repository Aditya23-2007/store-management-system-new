# PowerShell Tomcat 9 Silent Installer
# Extracts Tomcat 9, configures port, registers as service, and starts it.

param(
    [string]$TomcatPort = "8080"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [TOMCAT] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

# Check if Tomcat 9 service is already registered
$TomcatService = Get-Service -Name "Tomcat9" -ErrorAction SilentlyContinue
if ($TomcatService) {
    Write-Log "Apache Tomcat 9 service is already registered on this system."
    # Make sure it's running
    if ($TomcatService.Status -ne "Running") {
        Write-Log "Starting Apache Tomcat 9 service..."
        Start-Service Tomcat9
    }
    return
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$TomcatZip = Resolve-Path "$ScriptDir\..\redist\tomcat9.zip"
$TargetDir = "C:\Tomcat9"

# Extract Tomcat
if (Test-Path $TargetDir) {
    Write-Log "Warning: Directory $TargetDir already exists. Cleaning it before extraction..." "WARN"
    Remove-Item $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Log "Extracting Tomcat 9 to $TargetDir..."
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
Expand-Archive -Path $TomcatZip -DestinationPath "C:\Tomcat9_Temp" -Force

# Move the inner tomcat folder files directly into C:\Tomcat9
$InnerFolder = Get-ChildItem "C:\Tomcat9_Temp" -Directory | Select-Object -First 1
if ($InnerFolder) {
    Copy-Item -Path "$($InnerFolder.FullName)\*" -Destination $TargetDir -Recurse -Force
} else {
    Copy-Item -Path "C:\Tomcat9_Temp\*" -Destination $TargetDir -Recurse -Force
}
Remove-Item "C:\Tomcat9_Temp" -Recurse -Force | Out-Null

Write-Log "Configuring Tomcat Connector Port to $TomcatPort..."
$ServerXmlPath = "$TargetDir\conf\server.xml"
if (Test-Path $ServerXmlPath) {
    [xml]$xml = Get-Content $ServerXmlPath
    # Find HTTP Connector node (default port 8080) and set to TomcatPort
    $Connectors = $xml.Server.Service.Connector
    $HttpConnector = $Connectors | Where-Object { $_.protocol -like "*HTTP*" -or $_.port -eq "8080" }
    if ($HttpConnector) {
        $HttpConnector.port = $TomcatPort
        Write-Log "Updated HTTP Connector port in server.xml to $TomcatPort"
    } else {
        Write-Log "Could not locate the HTTP Connector in server.xml. Using default port settings." "WARN"
    }
    $xml.Save($ServerXmlPath)
} else {
    Write-Log "server.xml not found! Skipping port configuration." "WARN"
}

# Install Tomcat Service
Write-Log "Registering Tomcat 9 as a Windows Service..."
$ServiceBat = "$TargetDir\bin\service.bat"
if (-not (Test-Path $ServiceBat)) {
    throw "service.bat not found in Tomcat bin folder."
}

# Set environment variables for this session so service.bat can detect JDK
$env:JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")

# Execute service.bat to install Tomcat9
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$ServiceBat`" install Tomcat9" -WorkingDirectory "$TargetDir\bin" -Wait -NoNewWindow

# Verify service is created
$TomcatService = Get-Service -Name "Tomcat9" -ErrorAction SilentlyContinue
if (-not $TomcatService) {
    throw "Failed to install Apache Tomcat 9 service."
}

# Configure service to start automatically
Set-Service -Name "Tomcat9" -StartupType Automatic
Write-Log "Apache Tomcat 9 service configured to Start Automatically"

# Start the service
Write-Log "Starting Apache Tomcat 9 service..."
Start-Service Tomcat9
Write-Log "Apache Tomcat 9 service started successfully"
