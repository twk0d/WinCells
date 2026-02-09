# List of core requirements
$Requirements = [string[]]@("winget", "pwsh")

function Confirm-Minimum-Tools {
    <#
    .SYNOPSIS
        Checks for the existence of minimum required tools.
    .DESCRIPTION
        Iterates through the module $Requirements list to verify if tools are installed.
        Logs the status (Found/Missing) for each tool.
    .OUTPUTS
        [string[]] A list of tools that were not found.
    #>
    [OutputType([string[]])] # Documentation of type
    param()

    Write-Log -Message "Checking Minimum Required Tools" -Level 'INFO'
    
    [System.Collections.Generic.List[string]]$ToolsNotFound = @()

    foreach ($Tool in $Requirements) {
        if (Get-Command $Tool -ErrorAction SilentlyContinue) {
            Write-Log -Message "Found: $Tool" -Level 'SUCCESS'
        }
        else {
            Write-Log -Message "Missing: $Tool" -Level 'ERROR'
            $ToolsNotFound.Add($Tool)
        }
    }

    # Returns only the string array
    return [string[]]$ToolsNotFound
}

Export-ModuleMember -Function Confirm-Minimum-Tools -Variable Requirements
