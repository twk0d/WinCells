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
        if (Test-Tool -ToolName $Tool) {
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

function Test-Tool {
    <#
    .SYNOPSIS
        Checks for the existence of a specific tool.
    .DESCRIPTION
        Uses Get-Command to verify if the specified tool is installed.
    .PARAMETER ToolName
        The name of the tool to check for.
    .OUTPUTS
        [bool] True if the tool is found, otherwise False.
    #>
    [OutputType([bool])] # Documentation of type
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    return [bool](Get-Command $ToolName -ErrorAction SilentlyContinue)
}

Export-ModuleMember -Function Confirm-Minimum-Tools -Function Test-Tool
