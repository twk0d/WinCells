BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot "..\scripts\logs.psm1"
    Import-Module $ModulePath -Force
}

Describe "Write-Log" {
    BeforeEach {
        # Clean up any existing log file
        $global:LogPath = $null
    }

    Context "Basic functionality" {
        It "Accepts mandatory message parameter" {
            { Write-Log -Message "Test message" } | Should -Not -Throw
        }

        It "Uses INFO as default level" {
            { Write-Log -Message "Test" } | Should -Not -Throw
        }

        It "Accepts all valid log levels" {
            $levels = @('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'DEBUG', 'VERBOSE')
            foreach ($level in $levels) {
                { Write-Log -Message "Test" -Level $level } | Should -Not -Throw
            }
        }

        It "Rejects invalid log levels" {
            { Write-Log -Message "Test" -Level "INVALID" } | Should -Throw
        }
    }

    Context "Console output formatting" {
        It "Outputs formatted message with timestamp" {
            Mock Write-Information { } -ModuleName logs
            Mock Write-Host { } -ModuleName logs
            
            Write-Log -Message "Test message" -Level "INFO"
            
            Should -Invoke Write-Information -ModuleName logs -Times 1 -ParameterFilter {
                $MessageData -match '\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]' -and
                $MessageData -match '\[INFO\]' -and
                $MessageData -match 'Test message'
            }
        }

        It "Uses Write-Host for SUCCESS level" {
            Mock Write-Host { } -ModuleName logs
            
            Write-Log -Message "Success message" -Level "SUCCESS"
            
            Should -Invoke Write-Host -ModuleName logs -Times 1
        }

        It "Uses Write-Host for WARNING level" {
            Mock Write-Host { } -ModuleName logs
            Mock Write-Warning { } -ModuleName logs
            
            Write-Log -Message "Warning message" -Level "WARNING"
            
            Should -Invoke Write-Host -ModuleName logs -Times 1
        }

        It "Uses Write-Host for ERROR level" {
            Mock Write-Host { } -ModuleName logs
            Mock Write-Error { } -ModuleName logs
            
            Write-Log -Message "Error message" -Level "ERROR"
            
            Should -Invoke Write-Host -ModuleName logs -Times 1
        }
    }

    Context "File logging" {
        BeforeEach {
            $TestLogPath = Join-Path $TestDrive "test.log"
            $global:LogPath = $TestLogPath
        }

        AfterEach {
            $global:LogPath = $null
        }

        It "Writes to log file when global:LogPath is set" {
            Write-Log -Message "Test file log" -Level "INFO"
            
            Test-Path $global:LogPath | Should -Be $true
            $content = Get-Content $global:LogPath -Raw
            $content | Should -Match "Test file log"
        }

        It "Includes timestamp in file log" {
            Write-Log -Message "Timestamped message" -Level "INFO"
            
            $content = Get-Content $global:LogPath -Raw
            $content | Should -Match '\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]'
        }

        It "Includes level in file log" {
            Write-Log -Message "Level test" -Level "ERROR"
            
            $content = Get-Content $global:LogPath -Raw
            $content | Should -Match '\[ERROR\]'
        }

        It "Appends multiple log entries" {
            # Clear any existing content first
            if (Test-Path $global:LogPath) {
                Clear-Content $global:LogPath
            }
            
            Write-Log -Message "First entry" -Level "INFO"
            Write-Log -Message "Second entry" -Level "WARNING"
            
            $content = Get-Content $global:LogPath
            $content.Count | Should -Be 2
            $content[0] | Should -Match "First entry"
            $content[1] | Should -Match "Second entry"
        }

        It "Does not include ANSI color codes in file" {
            Write-Log -Message "No colors" -Level "INFO"
            
            $content = Get-Content $global:LogPath -Raw
            $content | Should -Not -Match "`e\["
        }
    }

    Context "Stream behavior" {
        It "Uses Write-Debug for DEBUG level" {
            Mock Write-Debug { } -ModuleName logs
            
            Write-Log -Message "Debug message" -Level "DEBUG"
            
            Should -Invoke Write-Debug -ModuleName logs -Times 1
        }

        It "Uses Write-Verbose for VERBOSE level" {
            Mock Write-Verbose { } -ModuleName logs
            
            Write-Log -Message "Verbose message" -Level "VERBOSE"
            
            Should -Invoke Write-Verbose -ModuleName logs -Times 1
        }
    }
}

AfterAll {
    # Clean up
    $global:LogPath = $null
    Remove-Module logs -ErrorAction SilentlyContinue
}
