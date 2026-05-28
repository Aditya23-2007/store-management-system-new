# PowerShell JDK 25 Silent Installer
# Installs Adoptium Temurin JDK 25 silently and configures environment variables.

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [JDK] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

# Helper to find existing java home
function Get-JavaHome {
    if ($env:JAVA_HOME -and (Test-Path $env:JAVA_HOME)) {
        return $env:JAVA_HOME
    }
    
    $regPath = "HKLM:\SOFTWARE\Eclipse Adoptium\JDK\25\hotspot\MSI"
    if (Test-Path $regPath) {
        $path = (Get-ItemProperty -Path $regPath).InstallationPath
        if (Test-Path $path) { return $path }
    }
    
    # Check default path
    $defaultPaths = @(
        "C:\Program Files\Eclipse Adoptium\jdk-25*",
        "C:\Program Files\Java\jdk-25*",
        "C:\Program Files\Java\jdk-17*",
        "C:\Program Files\Java\jdk-11*"
    )
    foreach ($pattern in $defaultPaths) {
        $parent = Split-Path $pattern
        $leaf = Split-Path $pattern -Leaf
        if (Test-Path $parent) {
            $match = Get-ChildItem -Path $parent -Filter $leaf -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($match) { return $match.FullName }
        }
    }
    return $null
}

$javaHome = Get-JavaHome
if ($javaHome) {
    Write-Log "Found Java JDK already installed at: $javaHome"
    # Ensure system environment variable is set
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
    Write-Log "Configured JAVA_HOME env variable to $javaHome"
    return
}

# Silent MSI installation
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MSIPath = Resolve-Path "$ScriptDir\..\redist\openjdk25.msi"

Write-Log "Installing JDK 25 silently from $MSIPath..."
$Arguments = "/i `"$MSIPath`" /quiet /qn /norestart ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome"

$Process = Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -NoNewWindow -PassThru
if ($Process.ExitCode -ne 0) {
    throw "Java JDK installer failed with exit code: $($Process.ExitCode)"
}

# Re-read Registry or check path to set environment variables
Start-Sleep -Seconds 3 # Wait for installer to finish registry updates
$javaHome = Get-JavaHome

if (-not $javaHome) {
    # If not found via registry, search in Program Files
    $matches = Get-ChildItem -Path "C:\Program Files\Eclipse Adoptium" -Filter "jdk-25*" -ErrorAction SilentlyContinue
    if ($matches) { $javaHome = $matches[0].FullName }
}

if (-not $javaHome) {
    throw "Java JDK was installed, but could not locate the installation path."
}

Write-Log "Java JDK installed successfully at $javaHome"
[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
Write-Log "Set JAVA_HOME environment variable to $javaHome"

# Add to path
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$javaHome\bin*") {
    [Environment]::SetEnvironmentVariable("Path", $currentPath + ";$javaHome\bin", "Machine")
    Write-Log "Added Java bin to Path"
}

# Apply to current process
$env:JAVA_HOME = $javaHome
$env:PATH = $env:PATH + ";$javaHome\bin"
Write-Log "Java JDK environment successfully configured"
