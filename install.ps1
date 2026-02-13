#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Main orchestration script for WinCells installation.
.DESCRIPTION
    Verifies the environment prerequisites, and manages the installation process.
#>

Import-Module "$PSScriptRoot/modules/core/scripts/logs.psm1" -Force
Import-Module "$PSScriptRoot/modules/core/scripts/environment.psm1" -Force
Import-Module "$PSScriptRoot/modules/core/configure-network.psm1" -Force
Import-Module "$PSScriptRoot/modules/core/scripts/install-app.psm1" -Force
$AppJson = "$PSScriptRoot/hosts/default/packages.json"
$InstallDevPackages = $false
$InstallOptionalPackages = $false
$InstallCorePackages = $true

$global:LogPath = "$PSScriptRoot/install.log"


#########################
### Verify Environment ###
#########################

# 1.1 Verify Tools
try {
    Write-Log -Message "Starting environment validation..." -Level 'INFO'
    
    [string[]]$FailedTools = Confirm-Minimum-Tools

    if ($FailedTools.Count -gt 0) {
        throw $FailedTools
    }

    ## TODO: Offer to download and install missing tools.

    Write-Log -Message "Environment validation completed successfully." -Level 'SUCCESS'
}
catch {
    $missing = $_.TargetObject
    Write-Log -Message "Validation failed. Missing: $($missing -join ', ')" -Level 'ERROR'
    
    if ($missing -contains "winget") {
        Write-Log -Message "WinGet is mandatory. Install 'App Installer' from Microsoft Store." -Level 'WARNING'
    }

    exit 1
}


########################
### Install Packages ###
########################

# 2.1 Install core Packages
try {
    if ($InstallCorePackages) {
        Install-Category -JsonPath $AppJson -Category "core"
    }
    else {
        Write-Log -Message "Skipping core packages installation as per configuration." -Level 'INFO'
    }
}
catch {
    write-Log -Message "Core packages installation encountered an error: $_" -Level 'ERROR'
}

# 2.2 Install dev Packages
try {
    if ($InstallDevPackages) {
        Install-Category -JsonPath $AppJson -Category "dev"
    }
    else {
        Write-Log -Message "Skipping dev packages installation as per configuration." -Level 'INFO'
    }
}
catch {
    write-Log -Message "Dev packages installation encountered an error: $_" -Level 'ERROR'
}

# 2.3 Install optional Packages
try {
    if ($InstallOptionalPackages) {
        Install-Category -JsonPath $AppJson -Category "optional"
    }
    else {
        Write-Log -Message "Skipping optional packages installation as per configuration." -Level 'INFO'
    }
}
catch {
    write-Log -Message "Optional packages installation encountered an error: $_" -Level 'ERROR'
}


##########################
### Configure Packages ###
##########################

# 2.3 Install optional Packages
try {
    Set-DefaultDNS
}
catch {
    write-Log -Message "Optional packages installation encountered an error: $_" -Level 'ERROR'
}

Read-Host -Prompt "Press Enter to exit"

