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
