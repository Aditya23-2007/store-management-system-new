# PowerShell Web Application Deployment and Compiler Script
# Extracts Maven, updates DBConnection.java, builds the WAR, deploys it to Tomcat, and sets up upload directory structures.

param(
    [string]$MySQLPort = "3306",
    [string]$MySQLPassword = "aditya@123",
    [string]$DBName = "store_db",
    [string]$WorkDir = "C:\StoreManagementWebApp"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [DEPLOY_WAR] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 1. Update DBConnection.java
Write-Log "Updating database settings in DBConnection.java..."
$ProjectDir = "$WorkDir\StoreManagementWebApp"
if (-not (Test-Path $ProjectDir)) {
    # Try WorkDir directly
    if (Test-Path "$WorkDir\src\main\java\com\store\util\DBConnection.java") {
        $ProjectDir = $WorkDir
    } else {
        throw "Could not locate project source directory at $WorkDir or $ProjectDir"
    }
}

$DbConnectionJavaPath = "$ProjectDir\src\main\java\com\store\util\DBConnection.java"
if (-not (Test-Path $DbConnectionJavaPath)) {
    throw "DBConnection.java file not found at $DbConnectionJavaPath"
}

# Update settings in DBConnection.java
$JavaCode = Get-Content -Path $DbConnectionJavaPath -Raw

# Replace port and db name in URL
$NewUrl = "jdbc:mysql://localhost:$MySQLPort/${DBName}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
$JavaCode = $JavaCode -replace 'private static final String URL = ".*?";', "private static final String URL = `"$NewUrl`";"
# Replace user
$JavaCode = $JavaCode -replace 'private static final String USER = ".*?";', "private static final String USER = `"root`";"
# Replace password
$JavaCode = $JavaCode -replace 'private static final String PASSWORD = ".*?";', "private static final String PASSWORD = `"$MySQLPassword`";"

Set-Content -Path $DbConnectionJavaPath -Value $JavaCode -Force
Write-Log "DBConnection.java successfully updated with correct credentials and port."

# 2. Extract Maven
$MavenBinDir = "C:\maven\apache-maven-3.9.6\bin"
$MvnCmd = "$MavenBinDir\mvn.cmd"

if (-not (Test-Path $MvnCmd)) {
    Write-Log "Apache Maven not found. Installing from archive..."
    $MavenZip = "$ScriptDir\..\redist\maven.zip"
    if (-not (Test-Path $MavenZip)) {
        throw "Maven redistributable zip package not found at $MavenZip."
    }
    
    if (Test-Path "C:\maven") {
        Remove-Item "C:\maven" -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path "C:\maven" -Force | Out-Null
    Write-Log "Extracting Maven to C:\maven..."
    Expand-Archive -Path $MavenZip -DestinationPath "C:\maven" -Force
    Write-Log "Maven successfully extracted."
} else {
    Write-Log "Found existing Maven installation at: C:\maven"
}

# 3. Compile Project via Maven
Write-Log "Compiling and packaging project using Maven..."
$JavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if (-not $JavaHome -or -not (Test-Path $JavaHome)) {
    throw "JAVA_HOME environment variable is not defined or invalid. Cannot build project."
}

# Set process environment variables for compiler execution
$env:JAVA_HOME = $JavaHome
$env:PATH = $env:PATH + ";$MavenBinDir"

# Run Maven build command
Write-Log "Running: mvn clean package"
$BuildProcess = Start-Process -FilePath $MvnCmd -ArgumentList "clean package" -WorkingDirectory $ProjectDir -Wait -NoNewWindow -PassThru
if ($BuildProcess.ExitCode -ne 0) {
    throw "Maven compilation and packaging failed with exit code $($BuildProcess.ExitCode)."
}
Write-Log "Maven project built successfully."

# Verify WAR exists
$WarPath = "$ProjectDir\target\StoreManagementWebApp.war"
if (-not (Test-Path $WarPath)) {
    throw "Target WAR file not found at $WarPath."
}

# 4. Stop Tomcat, Deploy WAR, Start Tomcat
Write-Log "Stopping Apache Tomcat 9 service for deployment..."
Stop-Service -Name "Tomcat9" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Log "Cleaning up existing ROOT deployment..."
$TomcatWebappsDir = "C:\Tomcat9\webapps"
if (-not (Test-Path $TomcatWebappsDir)) {
    throw "Tomcat webapps directory not found at $TomcatWebappsDir."
}

$RootWarTarget = "$TomcatWebappsDir\ROOT.war"
$RootFolderTarget = "$TomcatWebappsDir\ROOT"

if (Test-Path $RootWarTarget) { Remove-Item $RootWarTarget -Force }
if (Test-Path $RootFolderTarget) { Remove-Item $RootFolderTarget -Recurse -Force }

Write-Log "Copying WAR file and renaming to ROOT.war..."
Copy-Item -Path $WarPath -Destination $RootWarTarget -Force
Write-Log "WAR copied successfully."

Write-Log "Starting Apache Tomcat 9 service..."
Start-Service -Name "Tomcat9"

# 5. Wait for Tomcat to extract the WAR file
Write-Log "Waiting for Tomcat to unpack ROOT.war..."
$TimeoutSeconds = 45
$ElapsedSeconds = 0
$Unpacked = $false

$RootWebInf = "$RootFolderTarget\WEB-INF"

while ($ElapsedSeconds -lt $TimeoutSeconds) {
    if (Test-Path $RootWebInf) {
        $Unpacked = $true
        break
    }
    Start-Sleep -Seconds 2
    $ElapsedSeconds += 2
}

if (-not $Unpacked) {
    Write-Log "Warning: Tomcat did not unpack the WAR file in time. Proceeding, but folder permissions may need to be verified later." "WARN"
} else {
    Write-Log "Tomcat successfully unpacked ROOT.war."
}

# 6. Create Upload Folders and Set Permissions
Write-Log "Creating uploads folders..."
$UploadsBase = "$RootFolderTarget\uploads"
$Subfolders = @(
    "invoices",
    "purchase_orders",
    "payments",
    "challans",
    "cheques"
)

# Create folders
if (-not (Test-Path $UploadsBase)) {
    New-Item -ItemType Directory -Path $UploadsBase -Force | Out-Null
}

foreach ($sub in $Subfolders) {
    $fullPath = "$UploadsBase\$sub"
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Log "Created uploads subfolder: $sub"
    }
}

# Set full write permissions (ACL) on the uploads folder recursively
Write-Log "Configuring directory permissions for uploads..."
try {
    # Grant Everyone full access on the uploads folder
    $Acl = Get-Acl $UploadsBase
    $Permission = "Everyone","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $Permission
    $Acl.SetAccessRule($AccessRule)
    Set-Acl -Path $UploadsBase -AclObject $Acl
    Write-Log "Successfully configured write permissions for uploads directory."
} catch {
    Write-Log "Warning: Failed to set uploads directory permissions: $_" "WARN"
}

Write-Log "Deployment step completed successfully."
