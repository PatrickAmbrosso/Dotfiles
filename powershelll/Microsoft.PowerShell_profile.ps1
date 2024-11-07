# PowerShell $PROFILE Customization

# Disabling Directory Hightlight (PowerShell 7.3 specific)
$PSStyle.FileInfo.Directory = "" # Comment if you are using PowerShell 7.2 or lower

# Shell Autocompletion
# Original Source: https://dev.to/dhravya/how-to-add-autocomplete-to-powershell-in-30-seconds-2a8p

# Importing Terminal Icons
Import-Module Terminal-Icons

# Initializing the module
Import-Module PSReadLine

# Shows navigable menu of all options when hitting Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Autocompleteion for Arrow keys
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Setting options for screen updating
Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -PredictionSource History

# Asks Starship to use alternative location for Starship.toml file
$ENV:STARSHIP_CONFIG = "$ENV:USERPROFILE/.config/starship/starship.toml"
$ENV:STARSHIP_DISTRO = " "

# Triggers PowerShell to use Startship Prompt
Invoke-Expression (&starship init powershell)

# Display FastFetch Output on Screen
Write-Output "`n"
& fastfetch.exe

# Custom Functions
# Editor Configuration
# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

$EDITOR = if (Test-CommandExists code) { 'code' }
elseif (Test-CommandExists nvim) { 'nvim' }
elseif (Test-CommandExists pvim) { 'pvim' }
elseif (Test-CommandExists vim) { 'vim' }
elseif (Test-CommandExists vi) { 'vi' }
else { 'notepad' }
Set-Alias -Name edit -Value $EDITOR

function lsf {
    param(
        [switch]$Recursive
    )

    if ($Recursive) {
        Get-ChildItem -File -Recurse | Format-Table -Property Mode, LastWriteTime, Length, FullName -AutoSize
    }
    else {
        Get-ChildItem -File | Format-Table -Property Mode, LastWriteTime, Length, FullName -AutoSize
    }
}

function lsd {
    param(
        [string]$Path = (Get-Location),
        [switch]$Recursive
    )

    # Resolve the full path
    $fullPath = Resolve-Path -Path $Path

    # Check if the specified path exists and is a directory
    if (!(Test-Path -Path $fullPath -PathType Container)) {
        Write-Host "The specified path '$Path' does not exist or is not a directory." -ForegroundColor Red
        return
    }

    # Get the directories (recursive or not)
    $dirs = if ($Recursive) {
        Get-ChildItem -Directory -Path $fullPath -Recurse
    } else {
        Get-ChildItem -Directory -Path $fullPath
    }

    # Check if any directories are found
    if (-not $dirs) {
        Write-Host "No directories found in '$fullPath'." -ForegroundColor Yellow
        return
    }

    # Truncate directory paths to be relative to the specified path
    $relativeDirs = $dirs | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name RelativePath -Value ($_.FullName -replace [regex]::Escape($fullPath), "")
        $_
    }

    # Format the output table with truncated directory paths
    $relativeDirs | Format-Table -Property Mode, LastWriteTime, @{Name = "Path"; Expression = { $_.RelativePath } } -AutoSize

    # Print summary
    Write-Host "Directories listed from: $fullPath" -ForegroundColor Green
    Write-Host "Found $($relativeDirs.Count) Directories" -ForegroundColor Cyan
}


# Usage examples:
# lsd                        # Lists directories in the current directory
# lsd -Path "C:\SomeFolder"  # Lists directories in the specified directory
# lsd -r                     # Lists directories in the current directory 


# Make a Directory and cd into it
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        # Combine the arguments into a single string
        $argList = $args -join ' '
        # Run the command as administrator in Windows Terminal
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set alias
Set-Alias -Name su -Value admin

function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        # Get system start time using WMI for PowerShell 5
        $lastBootUpTime = Get-WmiObject win32_operatingsystem | 
            Select-Object @{Name='LastBootUpTime'; Expression={ $_.ConverttoDateTime($_.lastbootuptime) }} |
            Select-Object -ExpandProperty LastBootUpTime
    } else {
        # Get system start time using net statistics for PowerShell 7+
        $lastBootUpTimeString = net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
        $lastBootUpTime = [datetime]::Parse($lastBootUpTimeString)
    }

    # Calculate elapsed time since system start
    $uptimeSpan = New-TimeSpan -Start $lastBootUpTime

    # Create a custom object with system start time and uptime in HH:MM:SS
    $uptimeInfo = [pscustomobject]@{
        'Login Time'       = $lastBootUpTime
        'Elapsed Time'     = "{0:D2}:{1:D2}:{2:D2}" -f $uptimeSpan.Hours, $uptimeSpan.Minutes, $uptimeSpan.Seconds
    }

    # Output the object
    return $uptimeInfo
}


# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { param($m) git commit -m "$m" }

function gp { git push }

# Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }

function dtop { Set-Location -Path $HOME\Desktop }

function down { Set-Location -Path $HOME\Downloads }

function repo { Set-Location -Path $HOME\Documents\Git-Repositories } 

# Activate Zoxide
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

