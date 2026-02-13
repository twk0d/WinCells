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

    if ([string]::IsNullOrWhiteSpace($ToolName)) {
        throw "ToolName cannot be empty or whitespace."
    }

    return [bool](Get-Command $ToolName -ErrorAction SilentlyContinue)
}

function Test-WingetPackage {
    <#
    .SYNOPSIS
        Checks if a package is installed via winget.
    .DESCRIPTION
        Uses winget list to verify if the specified package is installed.
    .PARAMETER PackageName
        The name or ID of the package to check for.
    .OUTPUTS
        [bool] True if the package is found, otherwise False.
    #>
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    try {
        $result = winget list --id $PackageName 2>&1
        
        # Check if the package was found in the output
        if ($result -match [regex]::Escape($PackageName)) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

Export-ModuleMember -Function Confirm-Minimum-Tools, Test-Tool, Test-WingetPackage
