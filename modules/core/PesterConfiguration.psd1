# Pester Configuration File for WinCells Core Module Tests
# This file defines the test execution settings for all core module unit tests

@{
    Run = @{
        Path = "$PSScriptRoot\tests"
        Exit = $true
        PassThru = $true
    }
    
    CodeCoverage = @{
        Enabled = $true
        Path = @(
            "$PSScriptRoot\scripts\*.psm1"
            "$PSScriptRoot\*.psm1"
        )
        OutputFormat = 'JaCoCo'
        OutputPath = "$PSScriptRoot\tests\coverage.xml"
    }
    
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = "$PSScriptRoot\tests\test-results.xml"
    }
    
    Output = @{
        Verbosity = 'Detailed'
    }
    
    Should = @{
        ErrorAction = 'Stop'
    }
}
