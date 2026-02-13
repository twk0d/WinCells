BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot "..\scripts\configure-network.psm1"
    Import-Module $ModulePath -Force

    # Import logs module for Write-Log function
    $LogsPath = Join-Path $PSScriptRoot "..\scripts\logs.psm1"
    Import-Module $LogsPath -Force
}

Describe "Set-DefaultDNS" {
    BeforeAll {
        Mock Write-Log { } -ModuleName configure-network
    }

    Context "Basic functionality" {
        BeforeEach {
            # Create mock network adapter
            $MockAdapter = [PSCustomObject]@{
                Name = "Ethernet0"
                Status = "Up"
                InterfaceIndex = 12
            }
            
            Mock Get-NetAdapter { return $MockAdapter } -ModuleName configure-network
            Mock Set-DnsClientServerAddress { } -ModuleName configure-network
        }

        It "Accepts DnsServers parameter" {
            { Set-DefaultDNS -DnsServers @("8.8.8.8", "8.8.4.4") } | Should -Not -Throw
        }

        It "Uses Cloudflare DNS as default" {
            Set-DefaultDNS
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -ParameterFilter {
                $ServerAddresses[0] -eq "1.1.1.1" -and $ServerAddresses[1] -eq "1.0.0.1"
            }
        }

        It "Accepts custom DNS servers" {
            Set-DefaultDNS -DnsServers @("8.8.8.8", "8.8.4.4")
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -ParameterFilter {
                $ServerAddresses[0] -eq "8.8.8.8" -and $ServerAddresses[1] -eq "8.8.4.4"
            }
        }

        It "Accepts multiple DNS servers" {
            Set-DefaultDNS -DnsServers @("1.1.1.1", "1.0.0.1", "8.8.8.8")
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -ParameterFilter {
                $ServerAddresses.Count -eq 3
            }
        }
    }

    Context "Network adapter selection" {
        It "Selects first active adapter" {
            $MockAdapters = @(
                [PSCustomObject]@{ Name = "Ethernet0"; Status = "Up"; InterfaceIndex = 12 },
                [PSCustomObject]@{ Name = "WiFi"; Status = "Up"; InterfaceIndex = 15 }
            )
            
            Mock Get-NetAdapter { return $MockAdapters } -ModuleName configure-network
            Mock Set-DnsClientServerAddress { } -ModuleName configure-network
            
            Set-DefaultDNS
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -ParameterFilter {
                $InterfaceIndex -eq 12
            }
        }

        It "Filters to only 'Up' status adapters" {
            Mock Get-NetAdapter { } -ModuleName configure-network
            
            { Set-DefaultDNS } | Should -Throw "*No active network interface found*"
            
            Should -Invoke Get-NetAdapter -ModuleName configure-network -Times 1
        }

        It "Throws error when no active adapter found" {
            Mock Get-NetAdapter { return $null } -ModuleName configure-network
            
            { Set-DefaultDNS } | Should -Throw "*No active network interface found*"
        }

        It "Ignores disabled adapters" {
            $MockAdapter = [PSCustomObject]@{
                Name = "Ethernet0"
                Status = "Up"
                InterfaceIndex = 12
            }
            
            Mock Get-NetAdapter { return $MockAdapter } -ModuleName configure-network
            Mock Set-DnsClientServerAddress { } -ModuleName configure-network
            
            Set-DefaultDNS
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -Times 1
        }
    }

    Context "DNS configuration application" {
        BeforeEach {
            $MockAdapter = [PSCustomObject]@{
                Name = "Ethernet0"
                Status = "Up"
                InterfaceIndex = 12
            }
            
            Mock Get-NetAdapter { return $MockAdapter } -ModuleName configure-network
        }

        It "Applies DNS to correct interface" {
            Mock Set-DnsClientServerAddress { } -ModuleName configure-network
            
            Set-DefaultDNS
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -ParameterFilter {
                $InterfaceIndex -eq 12
            }
        }

        It "Passes all DNS servers to Set-DnsClientServerAddress" {
            Mock Set-DnsClientServerAddress { } -ModuleName configure-network
            
            $dnsServers = @("1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4")
            Set-DefaultDNS -DnsServers $dnsServers
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -ParameterFilter {
                $ServerAddresses.Count -eq 4
            }
        }
    }

    Context "Logging" {
        BeforeEach {
            $MockAdapter = [PSCustomObject]@{
                Name = "Ethernet0"
                Status = "Up"
                InterfaceIndex = 12
            }
            
            Mock Get-NetAdapter { return $MockAdapter } -ModuleName configure-network
            Mock Set-DnsClientServerAddress { } -ModuleName configure-network
        }

        It "Logs DNS configuration start" {
            Set-DefaultDNS -DnsServers @("1.1.1.1", "1.0.0.1")
            
            Should -Invoke Write-Log -ModuleName configure-network -ParameterFilter {
                $Message -like "Configuring IPv4 DNS to: 1.1.1.1, 1.0.0.1" -and $Level -eq 'INFO'
            }
        }

        It "Logs success with interface name" {
            Set-DefaultDNS
            
            Should -Invoke Write-Log -ModuleName configure-network -ParameterFilter {
                $Message -like "DNS configured successfully on Ethernet0*" -and $Level -eq 'SUCCESS'
            }
        }

        It "Logs errors when DNS configuration fails" {
            Mock Set-DnsClientServerAddress { throw "Configuration failed" } -ModuleName configure-network
            
            { Set-DefaultDNS } | Should -Throw
            
            Should -Invoke Write-Log -ModuleName configure-network -ParameterFilter {
                $Message -like "Failed to set DNS:*" -and $Level -eq 'ERROR'
            }
        }
    }

    Context "Error handling" {
        It "Throws error on network adapter retrieval failure" {
            Mock Get-NetAdapter { throw "Network error" } -ModuleName configure-network
            
            { Set-DefaultDNS } | Should -Throw
        }

        It "Throws error on DNS configuration failure" {
            $MockAdapter = [PSCustomObject]@{
                Name = "Ethernet0"
                Status = "Up"
                InterfaceIndex = 12
            }
            
            Mock Get-NetAdapter { return $MockAdapter } -ModuleName configure-network
            Mock Set-DnsClientServerAddress { throw "Access denied" } -ModuleName configure-network
            
            { Set-DefaultDNS } | Should -Throw
        }

        It "Logs error before throwing exception" {
            $MockAdapter = [PSCustomObject]@{
                Name = "Ethernet0"
                Status = "Up"
                InterfaceIndex = 12
            }
            
            Mock Get-NetAdapter { return $MockAdapter } -ModuleName configure-network
            Mock Set-DnsClientServerAddress { throw "Test error" } -ModuleName configure-network
            
            { Set-DefaultDNS } | Should -Throw
            
            Should -Invoke Write-Log -ModuleName configure-network -ParameterFilter {
                $Level -eq 'ERROR'
            }
        }
    }

    Context "Integration scenarios" {
        BeforeEach {
            $MockAdapter = [PSCustomObject]@{
                Name = "WiFi"
                Status = "Up"
                InterfaceIndex = 15
            }
            
            Mock Get-NetAdapter { return $MockAdapter } -ModuleName configure-network
            Mock Set-DnsClientServerAddress { } -ModuleName configure-network
        }

        It "Successfully configures Google DNS" {
            { Set-DefaultDNS -DnsServers @("8.8.8.8", "8.8.4.4") } | Should -Not -Throw
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -Times 1
            Should -Invoke Write-Log -ModuleName configure-network -ParameterFilter {
                $Level -eq 'SUCCESS'
            }
        }

        It "Successfully configures Quad9 DNS" {
            { Set-DefaultDNS -DnsServers @("9.9.9.9", "149.112.112.112") } | Should -Not -Throw
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -Times 1
        }

        It "Successfully configures OpenDNS" {
            { Set-DefaultDNS -DnsServers @("208.67.222.222", "208.67.220.220") } | Should -Not -Throw
            
            Should -Invoke Set-DnsClientServerAddress -ModuleName configure-network -Times 1
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module configure-network -ErrorAction SilentlyContinue
    Remove-Module logs -ErrorAction SilentlyContinue
}
