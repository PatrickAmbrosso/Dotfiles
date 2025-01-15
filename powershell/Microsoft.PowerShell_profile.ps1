# Pat's PowerShell Profile Customization

# Collect failure messages
$StartupLogs = @()

# Define Catppuccin Colors
$Catppuccin = @{
    rosewater = "#f5e0dc"
    flamingo  = "#f2cdcd"
    pink      = "#f5c2e7"
    mauve     = "#cba6f7"
    red       = "#f38ba8"
    maroon    = "#eba0ac"
    peach     = "#fab387"
    yellow    = "#f9e2af"
    green     = "#a6e3a1"
    teal      = "#94e2d5"
    sky       = "#89dceb"
    sapphire  = "#74c7ec"
    blue      = "#89b4fa"
    lavender  = "#b4befe"
    text      = "#cdd6f4"
    subtext1  = "#bac2de"
    subtext0  = "#a6adc8"
    overlay2  = "#9399b2"
    overlay1  = "#7f849c"
    overlay0  = "#6c7086"
    surface2  = "#585b70"
    surface1  = "#45475a"
    surface0  = "#313244"
    base      = "#1e1e2e"
    mantle    = "#181825"
    crust     = "#11111b"
}

# Disable Directory Highlights (only for PowerShell versions > 7.3)
$PSStyle.FileInfo.Directory = "" 

# Setup PSReadLine for commandline text completion
if (Get-Module -ListAvailable -Name PSReadLine) {

    # Import PSReadLine module
    Import-Module PSReadLine

    # Enhanced PSReadLine Configuration
    $PSReadLineOptions = @{
        EditMode                      = 'Windows'
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        Colors                        = @{
            Command                = $Catppuccin.mauve     # Mauve for commands
            Parameter              = $Catppuccin.green     # Green for parameters
            Operator               = $Catppuccin.peach     # Peach for operators
            Variable               = $Catppuccin.yellow    # Yellow for variables
            String                 = $Catppuccin.rosewater # Rosewater for strings
            Number                 = $Catppuccin.sky       # Sky for numbers
            Type                   = $Catppuccin.blue      # Blue for types
            Comment                = $Catppuccin.overlay1  # Subdued overlay for comments
            Keyword                = $Catppuccin.pink      # Pink for keywords
            Error                  = $Catppuccin.red       # Red for errors (high visibility)
            ListPrediction         = $Catppuccin.overlay0  # Color for prediction list items
            ListPredictionSelected = "`e[48;2;76;61;86m"   # Blended Mauve
            ListPredictionTooltip  = $Catppuccin.mauve     # Color for prediction tooltips
            Selection              = "`e[48;2;76;61;86m"   # Blended Mauve
        }
        PredictionSource              = 'History'
        PredictionViewStyle           = 'ListView'
        BellStyle                     = 'None'
    }

    Set-PSReadLineOption @PSReadLineOptions

    # Custom key handlers
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

    # Custom functions for PSReadLine
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
        $hasSensitive = $sensitive | Where-Object { $line -match $_ }
        return ($null -eq $hasSensitive)
    }

    # Improved prediction settings
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -MaximumHistoryCount 10000

}
else {

    # Log the failure message
    $StartupLogs += "Unable to import PSReadLine module. Check if it is installed."

}

# UTILITY FUNCTIONS =================================

function mkcd { 
    param($dir) 
    
    mkdir $dir -Force; Set-Location $dir 
}

function touch($file) { 
    "" | Out-File $file -Encoding ASCII 
}
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

function Test-CommandExists {

    param(
        [string]$Command,

        [switch]$Help
    )

    # Show help message if -Help is provided
    if ($Help) {
        @"
Usage: Test-CommandExists [-Help] <command>
Check if a command exists in the system's PATH.

Options:
    -Help            : Prints this help message.
    -Command         : Specify the command to check.

Notes:
    - If the command is not found, the function returns $false.
    - The function returns $true if the command is found.
"@
        return
    }

    # Check if the command exists
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Aliases for Test-CommandExists
function tc { Test-CommandExists @args }

function Yank {

    param (
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location), # Default to current directory if no path is specified

        [switch]$Content, # Copy file content to clipboard
        [switch]$PreviousCommand, # Copy the previous command to clipboard

        [switch]$Help # Help message
    )

    # Show help message if -Help is provided
    if ($Help) {
        @"
Usage: yank [-Content] <path>
Copy the current/specified path or previous shell command or file content to the clipboard.

Options:
    -Help            : Prints this help message.
    -Path            : Specify a file or directory path (default: current directory).
    -Content         : Copy the file content to the clipboard (only for files).
    -PreviousCommand : Copy the previous command to the clipboard.

Notes:
    - If -Content is specified, it copies the file content. Directories are not supported.
    - Without any switches, the current or specified path is copied to the clipboard.
    - If -PreviousCommand is specified, it copies the previous command to the clipboard.
    - Previous command is powered by the History, hence it is across all existing PowerShell sessions.
"@
        return
    }

    # Validate if the provided path exists
    if (-not (Test-Path $Path)) {
        Write-Error "Path '$Path' does not exist."
        return
    }

    # Resolve full path
    $FullPath = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path

    # Handle -Content switch
    if ($Content) {
        if (Test-Path $Path -PathType Container) {
            Write-Error "Cannot copy content of a directory. Path is a directory."
        }
        else {
            Set-Clipboard -Value (Get-Content -Path $FullPath -Raw)
            Write-Host "File content copied to clipboard."
        }
    }
    elseif ($PreviousCommand) {
        Set-Clipboard -Value (Get-History -Count 1 | Select-Object -ExpandProperty CommandLine)
        Write-Host "Previous command copied to clipboard."
    }
    else {
        # Default behavior: Copy the path
        Set-Clipboard -Value $FullPath
        Write-Host "Path copied to clipboard: $FullPath"
    }
}

# Aliases for Yank operations
function y { Yank @args }
function yc { Yank -Content @args }
function yp { Yank -PreviousCommand @args }

function Search {

    param (
        [switch]$Help, # Show help message

        # Search engine flags
        [switch]$Google,
        [switch]$DuckDuckGo,
        [switch]$Brave,
        [switch]$GoogleMaps,
        [switch]$DuckDuckGoMaps,
        [switch]$GitHub,
        [switch]$StackOverflow,
        [switch]$ChatGPT,
        [switch]$Claude,
        [switch]$Scoop,
        [switch]$Winget,
        [switch]$YouTube,
        [switch]$LinkedIn,
        [switch]$X, # Previously Twitter
        [switch]$Amazon,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Query  # Collect all remaining arguments as the query
    )

    # Show help message if -Help is provided
    if ($Help) {
        @"
Usage: Search [-Google] [-DuckDuckGo] [-Brave] [-Scoop] [-YouTube] [-GitHub] [-StackOverflow] [-Amazon] [-Winget] [-ChatGPT] [-LinkedIn] [-X] <query>
Search the web using a specified search engine.

Categories:
  General Search Engines:
    -Google        : Search using Google.
    -DuckDuckGo    : Search using DuckDuckGo (default).
    -Brave         : Search using Brave.

  Maps:
    -GoogleMaps    : Search using Google Maps.
    -DuckDuckGoMaps: Search using DuckDuckGo Maps.

  Developer/Technical Search:
    -GitHub        : Search repositories/issues on GitHub.
    -StackOverflow : Search questions on StackOverflow.
    -ChatGPT       : Search ChatGPT for a prompt.

  Package Management/Search:
    -Scoop         : Search for packages on Scoop.
    -Winget        : Search for packages on Winget.

  Media and Social Platforms:
    -YouTube       : Search on YouTube.
    -LinkedIn      : Search on LinkedIn.
    -X             : Search on X (formerly Twitter).

  E-Commerce:
    -Amazon        : Search for products on Amazon (India).

Notes:
    - If no search engine is specified, DuckDuckGo is used by default.
    - Any text after the search engine flag is used as the search query.
    - If more than one search engine is specified, the first valid engine is used.
"@
        return
    }

    # Dictionary of supported search engines
    $Engines = @{
        google         = "https://www.google.com/search?q="
        googlemaps     = "https://www.google.com/maps/search/?api=1&query="
        duckduckgo     = "https://duckduckgo.com/?q="
        duckduckgomaps = "https://duckduckgo.com/?t=h_&iaxm=maps&q="
        brave          = "https://search.brave.com/search?q="
        scoop          = "https://scoop.sh/#/apps?q="
        youtube        = "https://www.youtube.com/results?search_query="
        github         = "https://github.com/search?q="
        stackoverflow  = "https://stackoverflow.com/search?q="
        amazon         = "https://www.amazon.in/s?k="
        winget         = "https://winget.run/search?query="
        chatgpt        = "https://chat.openai.com/?q="
        linkedin       = "https://www.linkedin.com/search/results/all/?keywords="
        x              = "https://twitter.com/search?q="
    }

    # Extract valid engine flags from $PSBoundParameters
    $ValidKeys = @($PSBoundParameters.Keys | Where-Object { $Engines.ContainsKey($_.ToLower()) })

    # Determine the selected engine
    $SelectedEngine = if ($ValidKeys -and $ValidKeys.Count -gt 0) {
        ($ValidKeys[0] -as [string]).ToLower()  # Ensure it's a string before using ToLower
    }
    else {
        "duckduckgo"  # Default to DuckDuckGo
    }

    # Validate the selected engine
    if (-not $Engines.ContainsKey($SelectedEngine)) {
        Write-Error "Unsupported search engine: '$SelectedEngine'. Supported engines are: $($Engines.Keys -join ', ')"
        return
    }

    # Ensure a query is provided
    if (-not $Query -or $Query.Count -eq 0) {
        $Query = ""
    }

    # Build and launch the search URL
    $SearchQuery = $Query -join " "
    $SearchURL = $Engines[$SelectedEngine] + [uri]::EscapeDataString($SearchQuery)
    Start-Process $SearchURL
}

# Aliases for search operations
function s { Search @args }
function sddg { Search -DuckDuckGo @args }
function sscp { Search -Scoop @args }
function syt { Search -YouTube @args }

# EDITOR CONFIGURATION =================================

# Select the editor as per a preference matrix
$EDITOR = if (Test-CommandExists nvim) { 'code' }
elseif (Test-CommandExists hx) { 'hx' }
elseif (Test-CommandExists nvim) { 'nvim' }
elseif (Test-CommandExists vim) { 'vim' }
elseif (Test-CommandExists vi) { 'vi' }
elseif (Test-CommandExists notepad++) { 'notepad++' }
elseif (Test-CommandExists sublime_text) { 'sublime_text' }
else { 'notepad' }

# Setup Editor selection functionality for the preferred editor
function edit {
    param (
        [Parameter(Position = 0)]
        [string]$Path = "."  # Default to current directory
    )

    try {
        $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
        & $EDITOR $ResolvedPath
    }
    catch {
        & $EDITOR .
    }
}

# SETUP CLI TOOLS =================================

# Setup Zoxide
if (Test-CommandExists zoxide) {
    # Activate Zoxide
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}
else {
    $StartupLogs += "Unable to find zoxide (https://github.com/ajeetdsouza/zoxide)"
}

# Setup bat (alternative to cat)
if (Test-CommandExists bat) {
    $ENV:BAT_CONFIG_PATH = "$ENV:USERPROFILE/.config/bat/bat.conf"
    $ENV:BAT_CONFIG_DIR = "$ENV:USERPROFILE/.config/bat"
    Set-Alias -Name cat -Value bat
}
else {
    $StartupLogs += "Unable to find bat (https://github.com/sharkdp/bat)"
}

# Setup eza (alternative to ls/Get-ChildItem)
if (Test-CommandExists eza) {
    # Set the config directory
    $ENV:EZA_CONFIG_DIR = "$env:USERPROFILE\.config\eza"
    # Remove the default ls alias
    Remove-Alias -Name ls
    # Define command aliases for file & directory listings
    function ls { eza -la --group-directories-first --icons @args }
    function ld { eza -lh --group-directories-first --icons @args }
    # Define command aliases for tree printing operations
    function tree { eza -t --group-directories-first --icons  @args }
    function tree1 { eza --tree --group-directories-first --icons --level 1 @args }
    function tree2 { eza --tree --group-directories-first --icons --level 2 @args }
    function tree3 { eza --tree --group-directories-first --icons --level 3 @args }
    function tree4 { eza --tree --group-directories-first --icons --level 4 @args }
    function tree5 { eza --tree --group-directories-first --icons --level 5 @args }
}
else {
    $StartupLogs += "Unable to find eza locally installed (https://github.com/eza-community/eza)"
}


# Invoke FastFetch
if (Test-CommandExists fastfetch) {
    # Display FastFetch Output on Screen
    & fastfetch.exe
}
else {
    # Log the failure message
    $StartupLogs += "Unable to find fastfetch (https://github.com/fastfetch-cli/fastfetch)"
}

# Invoke Starship
if (Test-CommandExists starship) {
    # Set up Environment Variables for Starship
    $ENV:STARSHIP_CONFIG = "$ENV:USERPROFILE/.config/starship/starship.toml"
    # Triggers PowerShell to use Startship Prompt
    Invoke-Expression (&starship init powershell)
}
else {
    # Log the failure message
    $StartupLogs += "Unable to find starship (https://starship.rs/)"
}

# Report startup failures only if any
if ($StartupLogs.Count -gt 0) {
    Write-Host "`nStartup Failures:" -ForegroundColor Red
    $StartupLogs | ForEach-Object { Write-Host "`t- $($_)" }
}