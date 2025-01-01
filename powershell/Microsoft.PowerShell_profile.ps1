# Pat's PowerShell Profile Customization

# Disable Directory Highlights (only for PowerShell versions > 7.3)
$PSStyle.FileInfo.Directory = "" 

# Setup Terminal Icons
Import-Module Terminal-Icons

# Setup PSReadLine for commandline text completion
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
& fastfetch.exe

# Make a Directory and cd into it
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }


function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

function locate {
    param (
        [string]$CMD,
        [switch]$Yank
    )

    $path = Get-Command -Name $CMD -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue

    if ($path) {
        if ($Yank.IsPresent) {
            $path | Set-Clipboard
            Write-Host "Path copied to clipboard:" $path -ForegroundColor Green
        }
        else {
            Write-Host $path
        }
    }
    else {
        Write-Host "Unable to find $CMD" -ForegroundColor Red
    }
}


# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { param($m) git commit -m "$m" }

function gp { git push }

# Activate Zoxide
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

# Setup configurations for bat
$ENV:BAT_CONFIG_PATH = "$ENV:USERPROFILE/.config/bat/bat.conf"
$ENV:BAT_CONFIG_DIR = "$ENV:USERPROFILE/.config/bat"
Set-Alias -Name cat -Value bat


function Import-PSProfile {
    . $PROFILE
}
