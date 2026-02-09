function Write-Log {
    <#
    .SYNOPSIS
        Advanced logging function using Catppuccin Mocha colors and native PS streams.
    .PARAMETER Message
        The log message content.
    .PARAMETER Level
        The severity level: INFO, WARNING, ERROR, SUCCESS, DEBUG, VERBOSE.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'DEBUG', 'VERBOSE')]
        [string]$Level = 'INFO'
    )

    # Catppuccin Mocha ANSI Color Palette
    $C = @{
        Reset     = "`e[0m"
        Timestamp = "`e[38;2;147;153;178m" # Overlay2
        INFO      = "`e[38;2;137;180;250m" # Blue
        WARNING   = "`e[38;2;249;226;175m" # Yellow
        ERROR     = "`e[38;2;243;139;168m" # Red
        SUCCESS   = "`e[38;2;166;227;161m" # Green
        DEBUG     = "`e[38;2;203;166;247m" # Mauve
        VERBOSE   = "`e[38;2;148;226;213m" # Teal
    }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMsg = "$($C.Timestamp)[$Timestamp]$($C.Reset) $($C.$Level)[$Level]$($C.Reset) $Message"

    # Persistent logging to file (Plain text, no ANSI)
    if ($global:LogPath) {
        "[$Timestamp] [$Level] $Message" | Add-Content -Path $global:LogPath
    }

    # Dispatch to the appropriate PowerShell Stream
    switch ($Level) {
        'INFO' {
            # Use Write-Information (Stream 6) for standard tracking
            Write-Information -MessageData $FormattedMsg -InformationAction Continue
        }
        'SUCCESS' {
            # Success is usually treated as high-priority info
            Write-Host "$FormattedMsg"
        }
        'WARNING' {
            # Use Write-Warning (Stream 3). Note: Native 'WARNING:' prefix will be added.
            # We use Write-Host here to maintain the custom Catppuccin formatting.
            Write-Host "$FormattedMsg"
            Write-Warning -Message $Message -WarningAction SilentlyContinue
        }
        'ERROR' {
            # Use Write-Error (Stream 2) for non-terminating errors
            Write-Host "$FormattedMsg"
            Write-Error -Message $Message -ErrorAction SilentlyContinue
        }
        'DEBUG' {
            # Use Write-Debug (Stream 5). Only shows if $DebugPreference = 'Continue'
            Write-Debug -Message $FormattedMsg
        }
        'VERBOSE' {
            # Use Write-Verbose (Stream 4). Only shows if -Verbose switch is used
            Write-Verbose -Message $FormattedMsg
        }
    }
}

Export-ModuleMember -Function Write-Log
