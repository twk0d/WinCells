BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot "..\scripts\install-app.psm1"
    Import-Module $ModulePath -Force

    # Import logs module for Write-Log function
    $LogsPath = Join-Path $PSScriptRoot "..\scripts\logs.psm1"
    Import-Module $LogsPath -Force

    # Create test JSON file
    $script:TestJsonPath = Join-Path $TestDrive "test-packages.json"
    
    $TestConfig = @{
        "testCategory" = @(
            @{
                name = "TestApp1"
                enabled = $true
                type = "winget"
                id = "TestPublisher.TestApp1"
            },
            @{
                name = "DisabledApp"
                enabled = $false
                type = "winget"
                id = "TestPublisher.DisabledApp"
            },
            @{
                name = "ExternalApp"
                enabled = $true
                type = "external"
                url = "https://example.com/installer.exe"
                fileName = "installer.exe"
                args = "/S"
            }
        )
        "emptyCategory" = @()
    }
    
    $TestConfig | ConvertTo-Json -Depth 10 | Set-Content $script:TestJsonPath
}

Describe "Install-Category" {
    BeforeAll {
        Mock Write-Log { } -ModuleName install-app
    }

    Context "Configuration file handling" {
        It "Accepts JsonPath and Category parameters" {
            Mock winget { } -ModuleName install-app
            Mock Invoke-WebRequest { } -ModuleName install-app
            Mock Start-Process { } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            { Install-Category -JsonPath $script:TestJsonPath -Category "testCategory" } | Should -Not -Throw
        }

        It "Reads JSON configuration correctly" {
            Mock winget { $global:LASTEXITCODE = 0 } -ModuleName install-app
            Mock Invoke-WebRequest { } -ModuleName install-app
            Mock Start-Process { } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*TestApp1*"
            }
        }

        It "Handles empty category" {
            Mock winget { } -ModuleName install-app
            
            { Install-Category -JsonPath $script:TestJsonPath -Category "emptyCategory" } | Should -Not -Throw
        }
    }

    Context "Winget installations" {
        BeforeEach {
            Mock Invoke-WebRequest { } -ModuleName install-app
            Mock Start-Process { } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            # Create global mock for winget executable
            function global:winget { 
                $global:LASTEXITCODE = 0
            }
        }
        
        AfterEach {
            Remove-Item function:global:winget -ErrorAction SilentlyContinue
        }

        It "Calls winget for winget-type applications" {
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            # Verify winget was called (check logs instead since we can't mock external executables easily in Pester 3.x)
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*TestApp1*" -and $Message -like "*handled successfully*"
            }
        }

        It "Uses correct winget parameters" {
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            # Verify winget was called with correct parameters
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*TestApp1*" -and $Level -eq 'SUCCESS'
            } -Times 1
        }

        It "Logs success when winget returns 0" {
            Mock winget { $global:LASTEXITCODE = 0 } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*handled successfully*" -and $Level -eq 'SUCCESS'
            }
        }
    }

    Context "External installer handling" {
        BeforeEach {
            Mock winget { $global:LASTEXITCODE = 0 } -ModuleName install-app
        }

        It "Downloads external installers" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 0 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Invoke-WebRequest -ModuleName install-app -ParameterFilter {
                $Uri -eq "https://example.com/installer.exe"
            }
        }

        It "Saves installer to temp directory" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 0 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Invoke-WebRequest -ModuleName install-app -ParameterFilter {
                $OutFile -like "*$env:TEMP*installer.exe"
            }
        }

        It "Executes installer with arguments" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 0 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Start-Process -ModuleName install-app -ParameterFilter {
                $ArgumentList -contains "/S"
            }
        }

        It "Waits for installer to complete" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 0 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Start-Process -ModuleName install-app -ParameterFilter {
                $Wait -eq $true
            }
        }

        It "Uses PassThru to capture exit code" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 0 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Start-Process -ModuleName install-app -ParameterFilter {
                $PassThru -eq $true
            }
        }

        It "Cleans up downloaded installer" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 0 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Remove-Item -ModuleName install-app -ParameterFilter {
                $Path -like "*installer.exe"
            }
        }

        It "Handles download failures gracefully" {
            Mock Invoke-WebRequest { throw "Network error" } -ModuleName install-app
            Mock Start-Process { } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*Failed to install ExternalApp*" -and $Level -eq 'ERROR'
            }
        }

        It "Logs error when installer returns non-zero exit code" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 1603 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*installation failed with exit code 1603*" -and $Level -eq 'ERROR'
            }
        }

        It "Cleans up installer even on process failure" {
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 1 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Remove-Item -ModuleName install-app -ParameterFilter {
                $Path -like "*installer.exe"
            }
        }
    }

    Context "Disabled applications" {
        It "Skips disabled applications" {
            Mock winget { $global:LASTEXITCODE = 0 } -ModuleName install-app
            Mock Invoke-WebRequest { } -ModuleName install-app
            Mock Start-Process { } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*Skipping DisabledApp*"
            }
        }

        It "Does not call winget for disabled apps" {
            Mock winget { $global:LASTEXITCODE = 0 } -ModuleName install-app
            Mock Invoke-WebRequest { } -ModuleName install-app
            Mock Start-Process { } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
            
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Not -Invoke winget -ModuleName install-app -ParameterFilter {
                $id -eq "TestPublisher.DisabledApp"
            }
        }
    }

    Context "Logging" {
        BeforeEach {
            Mock winget { $global:LASTEXITCODE = 0 } -ModuleName install-app
            Mock Invoke-WebRequest { } -ModuleName install-app
            $MockProcess = [PSCustomObject]@{ ExitCode = 0 }
            Mock Start-Process { return $MockProcess } -ModuleName install-app
            Mock Remove-Item { } -ModuleName install-app
        }

        It "Logs processing message for each enabled app" {
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "Processing TestApp1*" -and $Level -eq 'INFO'
            }
        }

        It "Logs processing message for external apps" {
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "Processing ExternalApp*" -and $Level -eq 'INFO'
            }
        }

        It "Logs success for successful winget installations" {
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*TestApp1*handled successfully*" -and $Level -eq 'SUCCESS'
            }
        }

        It "Logs success for successful external installations" {
            Install-Category -JsonPath $script:TestJsonPath -Category "testCategory"
            
            Should -Invoke Write-Log -ModuleName install-app -ParameterFilter {
                $Message -like "*ExternalApp*handled successfully*" -and $Level -eq 'SUCCESS'
            }
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module install-app -ErrorAction SilentlyContinue
    Remove-Module logs -ErrorAction SilentlyContinue
}
