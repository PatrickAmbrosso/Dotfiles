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
$ProfileLocation = [System.IO.Path]::GetDirectoryName($PROFILE)
$ENV:STARSHIP_CONFIG = "$ProfileLocation/starship.toml"
$ENV:STARSHIP_DISTRO = " "

# Triggers PowerShell to use Startship Prompt
Invoke-Expression (&starship init powershell)

# Display WinFetch Output on Screen
& C:\Users\PatrickAmbrosso\Documents\PowerShell\Scripts\winfetch.ps1

# Commands and Alias Definitions
Set-Alias -Name "PWSSH" -Value "C:\Users\PatrickAmbrosso\.ssh\pwssh.ps1"