<#

.DESCRIPTION
    Application installation module for WinCells.
    Provides functions to install applications from JSON configuration files
    using winget or external installers.

.SYNOPSIS
    Installs applications from a specific category in a JSON configuration file.

.DESCRIPTION
    Reads a JSON configuration file and installs all enabled applications from the
    specified category. Supports two installation types:
    - winget: Installs via Windows Package Manager
    - external: Downloads and runs external installers from URL

.PARAMETER JsonPath
    Path to the JSON configuration file containing application definitions.
    The JSON should have categories as top-level properties, each containing
    an array of application objects.

.PARAMETER Category
    The category name to process from the JSON file.
    Must match a property name in the JSON configuration.

.EXAMPLE
    Install-Category -JsonPath "C:\config\packages.json" -Category "optional"
    Installs all enabled applications from the "optional" category.

.EXAMPLE
    Install-Category -JsonPath "./packages.json" -Category "dev-tools"
    Installs all enabled development tools from the configuration.

.NOTES
    Requires:
    - Administrative privileges for most installations
    - winget CLI for winget-based installations
    - Internet connectivity for downloading external installers
    
    Expected JSON structure:
    {
        "category": [
            {
                "name": "App Name",
                "enabled": true,
                "type": "winget",
                "id": "Publisher.AppName"
            },
            {
                "name": "External App",
                "enabled": true,
                "type": "external",
                "url": "https://example.com/installer.exe",
                "fileName": "installer.exe",
                "args": "/S"
            }
        ]
    }
#>
function Install-Category {
    param(
        [string]$JsonPath,
        [string]$Category
    )

    $Data = Get-Content $JsonPath | ConvertFrom-Json 
    $Apps = $Data.$Category

    foreach ($App in $Apps) {
        # Skip disabled applications
        if ($App.enabled -eq $false) {
            Write-Log -Message "Skipping $($App.name) (Disabled in config)." -Level 'INFO'
            continue
        }

        Write-Log -Message "Processing $($App.name)..." -Level 'INFO'

        # Reset exit code
        $LASTEXITCODE = 0

        # Handle installation based on type
        switch ($App.type) {
            "winget" {
                # Install using Windows Package Manager
                winget install --id $App.id --silent --accept-package-agreements --accept-source-agreements
            }
            "external" {
                try {
                    # Download installer to temp directory
                    $Path = "$env:TEMP\$($App.fileName)"
                    Invoke-WebRequest -Uri $App.url -OutFile $Path -ErrorAction Stop
                    
                    # Execute installer with provided arguments and wait for completion
                    $Process = Start-Process -FilePath $Path -ArgumentList $App.args -Wait -PassThru
                    
                    # Capture exit code from the process
                    $LASTEXITCODE = $Process.ExitCode
                    
                    # Clean up downloaded installer
                    Remove-Item $Path -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Log -Message "Failed to install $($App.name): $_" -Level 'ERROR'
                    $LASTEXITCODE = 1
                }
            }
        }

        # Check installation result and log success
        if ($LASTEXITCODE -eq 0) {
            Write-Log -Message "$($App.name) handled successfully." -Level 'SUCCESS'
        }
        else {
            Write-Log -Message "$($App.name) installation failed with exit code $LASTEXITCODE." -Level 'ERROR'
        }
    }
}

# Export function to make it available when module is imported
Export-ModuleMember -Function Install-Category