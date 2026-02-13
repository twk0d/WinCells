<#
.DESCRIPTION
    Core network configuration module for WinCells.
    Provides functions to configure DNS settings on Windows network interfaces.

.SYNOPSIS
    Configures DNS servers for the active network interface.

.DESCRIPTION
    Sets the DNS server addresses for the first active (Up) network interface.
    By default, uses Cloudflare DNS servers (1.1.1.1 and 1.0.0.1).
    Automatically detects the active network interface with internet connectivity.

.PARAMETER DnsServers
    Array of DNS server IP addresses to configure.
    Default: @("1.1.1.1", "1.0.0.1") - Cloudflare DNS

.EXAMPLE
    Set-DefaultDNS
    Configures the active network interface with Cloudflare DNS servers.

.EXAMPLE
    Set-DefaultDNS -DnsServers @("8.8.8.8", "8.8.4.4")
    Configures the active network interface with Google DNS servers.

.EXAMPLE
    Set-DefaultDNS -DnsServers @("1.1.1.1", "1.0.0.1", "8.8.8.8")
    Configures multiple DNS servers with Cloudflare primary and Google as fallback.
#>
function Set-DefaultDNS {
    param(
        [string[]]$DnsServers = @("1.1.1.1", "1.0.0.1") # Default: Cloudflare
    )

    try {
        Write-Log -Message "Configuring IPv4 DNS to: $($DnsServers -join ', ')" -Level 'INFO'

        # Find the first active network interface with internet connectivity
        # Only interfaces with "Up" status are considered
        $Interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

        if ($null -eq $Interface) {
            throw "No active network interface found."
        }

        # Apply DNS server configuration to the selected interface
        Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses $DnsServers
        
        Write-Log -Message "DNS configured successfully on $($Interface.Name)." -Level 'SUCCESS'
    }
    catch {
        Write-Log -Message "Failed to set DNS: $_" -Level 'ERROR'
        throw $_
    }
}

Export-ModuleMember -Function Set-DefaultDNS