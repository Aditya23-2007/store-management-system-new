# PowerShell Dependency Downloader
# Downloads the required installers and zips if they are not present locally.

$ErrorActionPreference = "Stop"

# Log helper
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [DOWNLOAD] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

# Define URLs
$JDK_URL = "https://api.adoptium.net/v3/installer/latest/25/ga/windows/x64/jdk/hotspot/normal/eclipse"
$TOMCAT_URL = "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.89/bin/apache-tomcat-9.0.89-windows-x64.zip"
$MYSQL_URL = "https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.36-winx64.zip"
$MAVEN_URL = "https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip"

# Directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RedistDir = "$ScriptDir\..\redist"
$TempRedistDir = "C:\StoreManagementSetupTemp\redist"

# Create directories
if (-not (Test-Path $RedistDir)) { New-Item -ItemType Directory -Path $RedistDir -Force | Out-Null }
if (-not (Test-Path $TempRedistDir)) { New-Item -ItemType Directory -Path $TempRedistDir -Force | Out-Null }

# Files definitions
$JDK_Path = "$RedistDir\openjdk25.msi"
$Tomcat_Path = "$RedistDir\tomcat9.zip"
$MySQL_Path = "$RedistDir\mysql8.zip"
$Maven_Path = "$RedistDir\maven.zip"

# Helper function to download file if not exists
function Ensure-File {
    param (
        [string]$Url,
        [string]$LocalPath,
        [string]$TempPath,
        [string]$Name
    )
    
    # Check if file exists in redist folder
    if (Test-Path $LocalPath) {
        Write-Log "Found local redistribution package for $Name at $LocalPath"
        return
    }
    
    # Check if file exists in temp folder from a previous attempt
    if (Test-Path $TempPath) {
        Write-Log "Found downloaded package for $Name in temp cache: $TempPath"
        # Copy to redist folder for consistency
        Copy-Item -Path $TempPath -Destination $LocalPath -Force
        return
    }
    
    Write-Log "Downloading $Name from $Url..."
    try {
        # Enable TLS 1.2 and 1.3
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        
        # Download to temp directory first, then copy to redist
        Start-BitsTransfer -Source $Url -Destination $TempPath -DisplayName "Downloading $Name" -ErrorAction Stop
        Copy-Item -Path $TempPath -Destination $LocalPath -Force
        Write-Log "Successfully downloaded and cached $Name"
    } catch {
        Write-Log "BITS transfer failed. Falling back to WebClient download..." "WARN"
        try {
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($Url, $TempPath)
            Copy-Item -Path $TempPath -Destination $LocalPath -Force
            Write-Log "Successfully downloaded $Name via WebClient fallback"
        } catch {
            throw "Failed to download $Name. Error: $_"
        }
    }
}

# Run downloads
Ensure-File -Url $JDK_URL -LocalPath $JDK_Path -TempPath "$TempRedistDir\openjdk25.msi" -Name "Java JDK 25"
Ensure-File -Url $TOMCAT_URL -LocalPath $Tomcat_Path -TempPath "$TempRedistDir\tomcat9.zip" -Name "Apache Tomcat 9"
Ensure-File -Url $MYSQL_URL -LocalPath $MySQL_Path -TempPath "$TempRedistDir\mysql8.zip" -Name "MySQL Server 8"
Ensure-File -Url $MAVEN_URL -LocalPath $Maven_Path -TempPath "$TempRedistDir\maven.zip" -Name "Apache Maven"

Write-Log "All external packages are present and verified."
