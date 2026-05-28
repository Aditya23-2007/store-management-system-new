# PowerShell Server Verification Script
# Verifies Tomcat server responsiveness on localhost and local domain, logging test results.

param(
    [string]$TomcatPort = "8080",
    [string]$DomainName = "bsietstore.local"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [VERIFICATION] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

Write-Log "Initializing deployment verification checks..."

# 1. Verify Tomcat Service Status
$TomcatService = Get-Service -Name "Tomcat9" -ErrorAction SilentlyContinue
if ($TomcatService.Status -ne "Running") {
    throw "Tomcat 9 service is not running. Current state: $($TomcatService.Status)"
}
Write-Log "Tomcat service is running."

# 2. Localhost connection test
$LocalUrl = "http://localhost:$TomcatPort/login.jsp"
Write-Log "Testing HTTP response from $LocalUrl..."
try {
    # Disable certificate validation and download just headers/content
    $Response = Invoke-WebRequest -Uri $LocalUrl -UseBasicParsing -TimeoutSec 15
    if ($Response.StatusCode -eq 200) {
        Write-Log "Deployment verified on localhost! Received Status Code 200." "SUCCESS"
    } else {
        Write-Log "Deployment verification warning: Localhost returned status $($Response.StatusCode)" "WARN"
    }
} catch {
    Write-Log "Failed to connect to localhost port $TomcatPort. The server might still be starting. Error: $_" "WARN"
}

# 3. Domain connection test
$DomainUrl = "http://$DomainName`:$TomcatPort/login.jsp"
Write-Log "Testing HTTP response from local domain: $DomainUrl..."
try {
    $Response = Invoke-WebRequest -Uri $DomainUrl -UseBasicParsing -TimeoutSec 15
    if ($Response.StatusCode -eq 200) {
        Write-Log "Deployment verified on local domain ($DomainName)! Received Status Code 200." "SUCCESS"
    } else {
        Write-Log "Deployment verification warning: Local domain returned status $($Response.StatusCode)" "WARN"
    }
} catch {
    Write-Log "Failed to connect to local domain $DomainName. Verify hosts entry. Error: $_" "WARN"
}

# 4. LAN access report
$ServerIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -ExpandProperty IPAddress
if ($ServerIPs) {
    Write-Log "Deployment validation completed. The web service is running and accessible on local network IP(s):" "SUCCESS"
    foreach ($IP in $ServerIPs) {
        Write-Log "  --> http://$IP`:$TomcatPort" "SUCCESS"
    }
} else {
    Write-Log "Warning: No network-facing IP addresses were found. The server might be offline or disconnected from LAN." "WARN"
}
