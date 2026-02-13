<#
.SYNOPSIS
    Executes all unit tests for WinCells Core modules

.DESCRIPTION
    This script runs Pester tests for all core PowerShell modules:
    - environment.psm1 - Environment and tool detection tests
    - logs.psm1 - Logging functionality tests
    - install-app.psm1 - Application installation tests
    - configure-network.psm1 - Network configuration tests

.PARAMETER Tag
    Optional tag to filter tests (e.g., "Fast", "Integration")

.PARAMETER CodeCoverage
    Generate code coverage report

.PARAMETER OutputFormat
    Test result output format: NUnitXml, JUnitXml, or None (default: NUnitXml)

.EXAMPLE
    .\Run-Tests.ps1
    Runs all tests with default settings

.EXAMPLE
    .\Run-Tests.ps1 -CodeCoverage
    Runs all tests and generates code coverage report

.EXAMPLE
    .\Run-Tests.ps1 -Tag "Fast"
    Runs only tests tagged as "Fast"
#>

[CmdletBinding()]
param(
    [string]$Tag,
    [switch]$CodeCoverage,
    [ValidateSet('NUnitXml', 'JUnitXml', 'None')]
    [string]$OutputFormat = 'NUnitXml'
)

# Ensure Pester is installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
}

# Import Pester
Import-Module Pester -MinimumVersion 5.0.0

# Set script location
$ScriptRoot = $PSScriptRoot
$TestsPath = Join-Path $ScriptRoot "tests"

Write-Host "`n=== WinCells Core Module Tests ===" -ForegroundColor Cyan
Write-Host "Test Path: $TestsPath`n" -ForegroundColor Gray

# Configure Pester
$configuration = New-PesterConfiguration

# Test discovery and execution
$configuration.Run.Path = $TestsPath
$configuration.Run.PassThru = $true

# Output settings
$configuration.Output.Verbosity = 'Detailed'

# Test results
if ($OutputFormat -ne 'None') {
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = $OutputFormat
    $configuration.TestResult.OutputPath = Join-Path $TestsPath "test-results.xml"
}

# Code coverage
if ($CodeCoverage) {
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @(
        (Join-Path $ScriptRoot "scripts\*.psm1"),
        (Join-Path $ScriptRoot "*.psm1")
    )
    $configuration.CodeCoverage.OutputFormat = 'JaCoCo'
    $configuration.CodeCoverage.OutputPath = Join-Path $TestsPath "coverage.xml"
}

# Filter by tag if specified
if ($Tag) {
    $configuration.Filter.Tag = $Tag
}

# Run tests
$result = Invoke-Pester -Configuration $configuration

# Display summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests:  $($result.TotalCount)" -ForegroundColor White
Write-Host "Passed:       $($result.PassedCount)" -ForegroundColor Green
Write-Host "Failed:       $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped:      $($result.SkippedCount)" -ForegroundColor Yellow

if ($CodeCoverage -and $result.CodeCoverage) {
    $coveragePercent = [math]::Round(($result.CodeCoverage.CommandsExecutedCount / $result.CodeCoverage.CommandsAnalyzedCount) * 100, 2)
    Write-Host "`nCode Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { 'Green' } elseif ($coveragePercent -ge 60) { 'Yellow' } else { 'Red' })
}

# Exit with appropriate code
if ($result.FailedCount -gt 0) {
    Write-Host "`nTests FAILED - See details above" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "`nAll tests PASSED!" -ForegroundColor Green
    exit 0
}