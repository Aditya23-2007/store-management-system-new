# PowerShell Firewall Configuration Script
# Configures Windows Defender Firewall inbound rules for Tomcat ports (80, 8080) and MySQL database port (3306).

param(
    [string]$TomcatPort = "80",
    [string]$MySQLPort = "3306"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] [FIREWALL] [$Level] $Message" | Out-File -FilePath "C:\StoreManagementWebApp_setup.log" -Append
    Write-Host "  -> $Message" -ForegroundColor Gray
}

try {
    # Delete old rules if they exist to avoid duplicates
    Remove-NetFirewallRule -DisplayName "Store Management System (Tomcat Port 80)" -ErrorAction SilentlyContinue | Out-Null
    Remove-NetFirewallRule -DisplayName "Store Management System (Tomcat Port 8080)" -ErrorAction SilentlyContinue | Out-Null
    Remove-NetFirewallRule -DisplayName "Store Management Database (MySQL)" -ErrorAction SilentlyContinue | Out-Null

    # Create new rule for Tomcat HTTP on Port 80
    Write-Log "Adding Inbound Firewall Rule for Tomcat Port 80..."
    New-NetFirewallRule -DisplayName "Store Management System (Tomcat Port 80)" `
                        -Description "Allows client connections to the Store Management Web Portal via HTTP port 80" `
                        -Direction Inbound `
                        -LocalPort 80 `
                        -Protocol TCP `
                        -Action Allow `
                        -Force | Out-Null

    # Create new rule for Tomcat HTTP on Port 8080
    Write-Log "Adding Inbound Firewall Rule for Tomcat Port 8080..."
    New-NetFirewallRule -DisplayName "Store Management System (Tomcat Port 8080)" `
                        -Description "Allows client connections to the Store Management Web Portal via default port 8080" `
                        -Direction Inbound `
                        -LocalPort 8080 `
                        -Protocol TCP `
                        -Action Allow `
                        -Force | Out-Null

    # Create new rule for MySQL Database on MySQLPort
    Write-Log "Adding Inbound Firewall Rule for MySQL port $MySQLPort..."
    New-NetFirewallRule -DisplayName "Store Management Database (MySQL)" `
                        -Description "Allows connections to the MySQL Database Server" `
                        -Direction Inbound `
                        -LocalPort $MySQLPort `
                        -Protocol TCP `
                        -Action Allow `
                        -Force | Out-Null

    # If the user-selected TomcatPort is different from 80 and 8080, open that too
    if ($TomcatPort -ne "80" -and $TomcatPort -ne "8080") {
        Remove-NetFirewallRule -DisplayName "Store Management System (Custom Port $TomcatPort)" -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "Store Management System (Custom Port $TomcatPort)" `
                            -Description "Allows client connections to the Store Management Web Portal via custom port $TomcatPort" `
                            -Direction Inbound `
                            -LocalPort $TomcatPort `
                            -Protocol TCP `
                            -Action Allow `
                            -Force | Out-Null
        Write-Log "Adding Inbound Firewall Rule for custom Tomcat port $TomcatPort..."
    }

    Write-Log "Inbound Firewall rules configured successfully using PowerShell cmdlets."
} catch {
    Write-Log "Advanced Firewall cmdlets not available or failed. Falling back to netsh utility..." "WARN"
    try {
        # Netsh fallback commands
        Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall delete rule name=`"Store Management System (Tomcat Port 80)`"" -Wait -NoNewWindow | Out-Null
        Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall delete rule name=`"Store Management System (Tomcat Port 8080)`"" -Wait -NoNewWindow | Out-Null
        Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall delete rule name=`"Store Management Database (MySQL)`"" -Wait -NoNewWindow | Out-Null

        Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall add rule name=`"Store Management System (Tomcat Port 80)`" dir=in action=allow protocol=TCP localport=80" -Wait -NoNewWindow | Out-Null
        Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall add rule name=`"Store Management System (Tomcat Port 8080)`" dir=in action=allow protocol=TCP localport=8080" -Wait -NoNewWindow | Out-Null
        Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall add rule name=`"Store Management Database (MySQL)`" dir=in action=allow protocol=TCP localport=$MySQLPort" -Wait -NoNewWindow | Out-Null
        
        if ($TomcatPort -ne "80" -and $TomcatPort -ne "8080") {
            Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall delete rule name=`"Store Management System (Custom Port $TomcatPort)`"" -Wait -NoNewWindow | Out-Null
            Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall firewall add rule name=`"Store Management System (Custom Port $TomcatPort)`" dir=in action=allow protocol=TCP localport=$TomcatPort" -Wait -NoNewWindow | Out-Null
        }
        
        Write-Log "Inbound Firewall rules configured successfully using netsh utility."
    } catch {
        throw "Failed to configure Windows Firewall rules. Error: $_"
    }
}
