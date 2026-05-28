# PowerShell Static IP Configuration Script
# Configures the active network adapter with the provided static IP settings.

param(
    [string]$IPAddress = "192.168.1.100",
    [string]$SubnetMask = "255.255.255.0",
    [string]$Gateway = "192.168.1.1",
    [string]$DNS = "8.8.8.8"
)

$ErrorActionPreference = "Continue" # Don't halt the entire setup if adapter properties are locked

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [STATIC_IP] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

Write-Log "Checking active network adapters for static IP configuration..."

# Find the active adapter routing internet traffic (default gateway adapter)
$ActiveRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $ActiveRoute) {
    # Fallback: get any active IPv4 interface that isn't loopback
    $ActiveInterface = Get-NetIPInterface -AddressFamily IPv4 -ConnectionState Connected | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1
} else {
    $ActiveInterface = Get-NetIPInterface -InterfaceIndex $ActiveRoute.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
}

if (-not $ActiveInterface) {
    Write-Log "No active IPv4 network interface found. Skipping static IP assignment." "WARN"
    return
}

$InterfaceIndex = $ActiveInterface.InterfaceIndex
$InterfaceAlias = $ActiveInterface.InterfaceAlias

Write-Log "Active network interface detected: '$InterfaceAlias' (Index: $InterfaceIndex)"

try {
    # Check if the desired IP is already configured
    $CurrentIPs = Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
    if ($CurrentIPs -contains $IPAddress) {
        Write-Log "Static IP $IPAddress is already configured on adapter '$InterfaceAlias'." "SUCCESS"
        return
    }
    
    Write-Log "Configuring Static IP $IPAddress on adapter '$InterfaceAlias'..."
    
    # Calculate PrefixLength from SubnetMask
    $PrefixLength = 24
    if ($SubnetMask) {
        try {
            $ipBytes = [System.Net.IPAddress]::Parse($SubnetMask).GetAddressBytes()
            $bits = 0
            foreach ($byte in $ipBytes) {
                while ($byte -gt 0) {
                    $bits += ($byte -band 1)
                    $byte = $byte -shr 1
                }
            }
            if ($bits -gt 0 -and $bits -le 32) {
                $PrefixLength = $bits
            }
        } catch {
            Write-Log "Invalid subnet mask format, falling back to /24." "WARN"
        }
    }

    # 1. Remove existing DHCP/IP routes if necessary, and assign Static IP
    # We use New-NetIPAddress. If DHCP was active, Windows will transition the adapter to static.
    $NewIPResult = New-NetIPAddress -InterfaceIndex $InterfaceIndex `
                                    -IPAddress $IPAddress `
                                    -PrefixLength $PrefixLength `
                                    -DefaultGateway $Gateway `
                                    -Force -ErrorAction Stop
                                    
    # 2. Configure DNS Server 
    Write-Log "Configuring DNS Server $DNS on adapter '$InterfaceAlias'..."
    Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex `
                               -ServerAddresses @($DNS) `
                               -ErrorAction Stop
                               
    Write-Log "Static IP configuration completed successfully: IP=$IPAddress, Netmask=$SubnetMask, Gateway=$Gateway, DNS=$DNS" "SUCCESS"
} catch {
    Write-Log "Failed to automatically configure static IP. You may need to set it manually. Error: $_" "WARN"
}
