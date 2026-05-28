# PowerShell Domain Hosts Configuration Script
# Configures the server hosts file and generates a sharing-ready client host mapping script.

param(
    [string]$DomainName = "bsietstore.local"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [HOSTS] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

$HostsPath = "C:\Windows\System32\drivers\etc\hosts"

# 1. Update Server's hosts file
Write-Log "Configuring local domain '$DomainName' on Server PC hosts file..."
$HostsContent = Get-Content -Path $HostsPath -Raw

if ($HostsContent -notlike "*$DomainName*") {
    $LineToAdd = "`r`n127.0.0.1`t$DomainName"
    Add-Content -Path $HostsPath -Value $LineToAdd -Force
    Write-Log "Successfully mapped $DomainName to 127.0.0.1 on the Server PC."
} else {
    Write-Log "Local domain '$DomainName' mapping already exists on the Server PC."
}

# 2. Get Server LAN IP address to generate Client script
Write-Log "Identifying Server LAN IP Address..."
$ServerIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -ExpandProperty IPAddress
$ServerIP = $ServerIPs | Select-Object -First 1

if (-not $ServerIP) {
    $ServerIP = "127.0.0.1"
    Write-Log "Warning: No active LAN IP address detected. Defaulting client config template to loopback." "WARN"
} else {
    Write-Log "Server LAN IP Address detected: $ServerIP"
}

# 3. Create client setup folder and script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ClientSetupFolder = "$ScriptDir\..\client_setup"

if (-not (Test-Path $ClientSetupFolder)) {
    New-Item -ItemType Directory -Path $ClientSetupFolder -Force | Out-Null
}

$ClientHostsScriptPath = "$ClientSetupFolder\configure_client_hosts.ps1"

# Design a premium PowerShell script that client PCs can run as Administrator
$ClientScriptCode = @"
# Client hosts configuration script for Store Management System
# Maps '$DomainName' to the Server IP address '$ServerIP'.
# MUST BE RUN AS ADMINISTRATOR ON CLIENT PCS.

try {
    # Check Administrative privileges
    `$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    `$principal = New-Object Security.Principal.WindowsPrincipal(`$identity)
    if (-not `$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Please run this script as Administrator."
        Write-Host "Press any key to exit..."
        [void]`$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    `$HostsPath = "C:\Windows\System32\drivers\etc\hosts"
    `$HostsContent = Get-Content -Path `$HostsPath -Raw
    `$Domain = "$DomainName"
    `$ServerIP = "$ServerIP"

    # Remove any existing mappings for this domain
    if (`$HostsContent -like "*`$Domain*") {
        # Filter out lines containing the domain name
        `$CleanedLines = Get-Content `$HostsPath | Where-Object { `$_.Trim() -notlike "*`$Domain*" }
        Set-Content -Path `$HostsPath -Value `$CleanedLines -Force
    }

    # Append the new mapping
    `$LineToAdd = "`r`n``$ServerIP`t``$Domain"
    Add-Content -Path `$HostsPath -Value `$LineToAdd -Force
    
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "CLIENT NETWORK ROUTING SUCCESSFUL!" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "Local domain: http://`$Domain:8080" -ForegroundColor Cyan
    Write-Host "Direct Server Access: http://`$ServerIP:8080" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to exit..."
    [void]`$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {
    Write-Error "Failed to update hosts file on client. Error: `$PSItem"
    Write-Host "Press any key to exit..."
    [void]`$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
"@

$ClientScriptCode | Set-Content -Path $ClientHostsScriptPath -Force
Write-Log "Client hosts configuration template created at: $ClientHostsScriptPath"
Write-Log "Administrator can run this client script on other computers in the LAN."
