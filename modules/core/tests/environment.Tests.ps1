BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot "..\scripts\environment.psm1"
    Import-Module $ModulePath -Force

    # Import logs module for Write-Log function
    $LogsPath = Join-Path $PSScriptRoot "..\scripts\logs.psm1"
    Import-Module $LogsPath -Force
}

Describe "Test-Tool" {
    Context "When tool exists" {
        It "Returns true for existing PowerShell command" {
            $result = Test-Tool -ToolName "Get-Command"
            $result | Should -Be $true
        }

        It "Returns true for pwsh" {
            $result = Test-Tool -ToolName "pwsh"
            $result | Should -Be $true
        }
    }

    Context "When tool does not exist" {
        It "Returns false for non-existent tool" {
            $result = Test-Tool -ToolName "NonExistentTool12345"
            $result | Should -Be $false
        }

        It "Throws error for empty string" {
            { Test-Tool -ToolName "" } | Should -Throw
        }

        It "Throws error for whitespace string" {
            { Test-Tool -ToolName "   " } | Should -Throw "*cannot be empty*"
        }

        It "Throws error for null string" {
            { Test-Tool -ToolName $null } | Should -Throw
        }
    }
}

Describe "Test-WingetPackage" {
    Context "When checking package installation" {
        It "Accepts a package name parameter" {
            { Test-WingetPackage -PackageName "TestPackage" } | Should -Not -Throw
        }

        It "Returns a boolean value" {
            $result = Test-WingetPackage -PackageName "TestPackage"
            $result | Should -BeOfType [bool]
        }

        It "Returns true when package is found in winget list output" {
            Mock winget { 
                return "Name Id Version Available Source\nTest Package TestPackage 1.0.0 1.0.1 winget"
            } -ModuleName environment
            
            $result = Test-WingetPackage -PackageName "TestPackage"
            $result | Should -Be $true
        }

        It "Returns false when package is not found in winget list output" {
            Mock winget { 
                return "Name Id Version Available Source\nOther Package OtherPackage 1.0.0 1.0.1 winget"
            } -ModuleName environment
            
            $result = Test-WingetPackage -PackageName "TestPackage"
            $result | Should -Be $false
        }

        It "Handles errors gracefully" {
            Mock winget { throw "Error" } -ModuleName environment
            $result = Test-WingetPackage -PackageName "TestPackage"
            $result | Should -Be $false
        }

        It "Uses --id parameter when calling winget" {
            Mock winget { return "" } -ModuleName environment
            
            Test-WingetPackage -PackageName "TestPackage" | Out-Null
            
            Should -Invoke winget -ModuleName environment -ParameterFilter {
                $args -contains "--id" -and $args -contains "TestPackage"
            }
        }

        It "Handles special regex characters in package names" {
            Mock winget { 
                return "Name Id Version\nTest.Package Test.Package 1.0.0"
            } -ModuleName environment
            
            $result = Test-WingetPackage -PackageName "Test.Package"
            $result | Should -Be $true
        }
    }
}

Describe "Confirm-Minimum-Tools" {
    BeforeAll {
        # Create a mock for Write-Log
        Mock Write-Log { } -ModuleName environment
    }

    Context "When all tools are present" {
        It "Returns empty array when all required tools exist" {
            Mock Test-Tool { $true } -ModuleName environment
            
            $result = Confirm-Minimum-Tools
            
            # PowerShell can return $null for empty arrays in some contexts
            # Check that either it's null/empty or has 0 count
            if ($null -eq $result) {
                $true | Should -Be $true
            } else {
                $result.Count | Should -Be 0
            }
        }

        It "Logs success messages for found tools" {
            Mock Test-Tool { $true } -ModuleName environment
            
            Confirm-Minimum-Tools
            
            Should -Invoke Write-Log -ModuleName environment -Times 1 -ParameterFilter {
                $Message -eq "Checking Minimum Required Tools" -and $Level -eq 'INFO'
            }
        }
    }

    Context "When tools are missing" {
        It "Returns array of missing tools" {
            Mock Test-Tool { 
                param($ToolName)
                if ($ToolName -eq "winget") { return $false }
                if ($ToolName -eq "pwsh") { return $true }
            } -ModuleName environment
            
            $result = Confirm-Minimum-Tools
            
            $result | Should -Contain "winget"
            $result.Count | Should -Be 1
        }

        It "Returns all missing tools when none exist" {
            Mock Test-Tool { $false } -ModuleName environment
            
            $result = Confirm-Minimum-Tools
            
            $result.Count | Should -Be 2
            $result | Should -Contain "winget"
            $result | Should -Contain "pwsh"
        }

        It "Logs error messages for missing tools" {
            Mock Test-Tool { $false } -ModuleName environment
            
            Confirm-Minimum-Tools
            
            Should -Invoke Write-Log -ModuleName environment -ParameterFilter {
                $Level -eq 'ERROR'
            } -Times 2
        }
    }
}

AfterAll {
    # Clean up imported modules
    Remove-Module environment -ErrorAction SilentlyContinue
    Remove-Module logs -ErrorAction SilentlyContinue
}
