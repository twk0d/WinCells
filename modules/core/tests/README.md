# WinCells Core Module Tests

This directory contains comprehensive unit tests for all WinCells core PowerShell modules using the Pester testing framework.

## Test Files

- **environment.Tests.ps1** - Tests for environment and tool detection functions
  - `Test-Tool` - Verifies tool existence
  - `Test-WingetPackage` - Checks winget package installation
  - `Confirm-Minimum-Tools` - Validates all required tools

- **logs.Tests.ps1** - Tests for logging functionality
  - `Write-Log` - Tests log output, formatting, file logging, and streams

- **install-app.Tests.ps1** - Tests for application installation
  - `Install-Category` - Tests winget and external installer workflows

- **configure-network.Tests.ps1** - Tests for network configuration
  - `Set-DefaultDNS` - Tests DNS configuration on network adapters

## Prerequisites

### Pester Testing Framework

This test suite uses **Pester 5.5.0**, a powerful BDD-style testing framework for PowerShell.

**About Pester:**
- Provides a framework for running BDD style tests to execute and validate PowerShell commands
- Offers powerful Mocking Functions that allow tests to mimic and mock any command
- Can execute any command or script accessible to a Pester test
- Minimum PowerShell version: 3.0
- Current version: 5.5.0

**Installation Options:**

```powershell
# Install specific version (recommended)
Install-Module -Name Pester -RequiredVersion 5.5.0 -Force -SkipPublisherCheck -Scope CurrentUser

# Or install latest version
Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser

# Using PSResourceGet (PowerShell 7+)
Install-PSResource -Name Pester -Version 5.5.0
```

**Verify Installation:**

```powershell
Get-Module -Name Pester -ListAvailable

# Should output:
# ModuleType Version    Name
# ---------- -------    ----
# Script     5.5.0      Pester
```

## Running Tests

### Run All Tests
```powershell
# From the core module directory
.\Run-Tests.ps1
```

### Run with Code Coverage
```powershell
.\Run-Tests.ps1 -CodeCoverage
```

### Run Specific Test File
```powershell
Invoke-Pester -Path .\tests\environment.Tests.ps1
```

### Run Tests with Detailed Output
```powershell
Invoke-Pester -Path .\tests\ -Output Detailed
```

## Test Structure

Each test file follows this pattern:

```powershell
BeforeAll {
    # Import modules under test
}

Describe "FunctionName" {
    Context "Specific scenario" {
        It "Should do something" {
            # Test assertion
        }
    }
}

AfterAll {
    # Cleanup
}
```

## Test Coverage

The tests cover:
- **Happy paths** - Normal operation scenarios
- **Error handling** - Exception and error scenarios
- **Edge cases** - Boundary conditions and special cases
- **Mocking** - External dependencies are mocked for isolation
- **Parameter validation** - Input validation testing
- **Logging** - Verification of log messages

## Mocking Strategy

External dependencies are mocked to ensure:
- Tests run without actual system modifications
- Tests are fast and deterministic
- Tests can run in CI/CD pipelines

Mocked cmdlets include:
- `Get-Command` - For tool detection
- `winget` - For package management
- `Get-NetAdapter` - For network adapter queries
- `Set-DnsClientServerAddress` - For DNS configuration
- `Invoke-WebRequest` - For file downloads
- `Start-Process` - For installer execution

## Test Reports

Test results are generated in:
- `test-results.xml` - NUnit format (default)
- `coverage.xml` - JaCoCo format (when -CodeCoverage is used)

## CI/CD Integration

The test suite is designed for CI/CD integration.

## Best Practices

1. **Keep tests isolated** - Use BeforeEach/AfterEach for test setup/teardown
2. **Use descriptive names** - Test names should clearly describe what is tested
3. **Mock external dependencies** - Don't make real system calls
4. **Test one thing per test** - Each It block should test a single behavior
5. **Use appropriate assertions** - Choose the right Should operator

## Troubleshooting

### Tests fail with "Module not found"
Ensure you're running tests from the correct directory and module paths are correct.

### Mock not being invoked
Check the `-ModuleName` parameter matches the module being mocked.

### Code coverage not generated
Ensure `-CodeCoverage` switch is used and paths in coverage configuration are correct.

## Contributing

When adding new functions to core modules:
1. Create corresponding test cases
2. Ensure minimum 80% code coverage
3. Test both success and failure scenarios
4. Add appropriate mocks for external dependencies
5. Update this README if needed
