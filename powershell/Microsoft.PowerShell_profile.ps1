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

# EDITOR SETUP ======================================
$global:EDITOR = $global:EDITOR ?? (Get-Command code, hx, nvim, vim, vi, notepad++, sublime_text, notepad -ErrorAction SilentlyContinue | Select-Object -First 1).Name

function edit {
    param (
        [Parameter(Position = 0)]
        [string]$Path = "."  # Default to current directory
    )

    try {
        $Resolved = Resolve-Path -Path $Path -ErrorAction Stop
        & $global:EDITOR $Resolved
    }
    catch {
        Write-Host "Could not resolve '$($Path)'. Opening default editor in current directory." -ForegroundColor Yellow
        & $global:EDITOR .
    }
}

# UTILITY FUNCTIONS =================================

function mkcd { 
    param($dir) 
    
    mkdir $dir -Force; Set-Location $dir 
}

function touch {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Path
    )
    if (Test-Path $Path) {
        Write-Host "File already exists at $Path" -ForegroundColor DarkGray
    }
    else {
        "" | Out-File -FilePath $Path -Encoding UTF8
        Write-Host "File newly created at $Path" -ForegroundColor White
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

function unzip {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string[]]$Pattern,  # Accepts multiple patterns or files

        [string]$Destination = $PWD
    )

    $archives = @()

    foreach ($p in $Pattern) {
        $resolved = Resolve-Path -Path $p -ErrorAction SilentlyContinue

        if ($resolved) {
            foreach ($r in $resolved) {
                if (Test-Path $r.Path -PathType Leaf) {
                    $archives += Get-Item -Path $r.Path
                }
            }
        }
        else {
            $basePath = Split-Path -Path $p -Parent
            $fileName = Split-Path -Path $p -Leaf
            if (-not $basePath) { $basePath = $PWD }

            if (-not (Test-Path $basePath)) {
                Write-Host "Path does not exist: $basePath" -ForegroundColor Red
                continue
            }

            $MatchingEntries = Get-ChildItem -Path $basePath -Filter $fileName -File -ErrorAction SilentlyContinue
            $archives += $MatchingEntries
        }
    }

    if (-not $archives -or $archives.Count -eq 0) {
        Write-Host "No matching archives found." -ForegroundColor Red
        return
    }

    if (-not (Test-Path $Destination)) {
        try {
            New-Item -Path $Destination -ItemType Directory -Force | Out-Null
            Write-Host "Destination directory created: $Destination" -ForegroundColor Gray
        }
        catch {
            Write-Host "Failed to create destination directory: $Destination" -ForegroundColor Red
            Write-Host " → $($_.Exception.Message)" -ForegroundColor DarkGray
            return
        }
    }

    foreach ($archive in $archives | Sort-Object FullName -Unique) {
        try {
            Expand-Archive -Path $archive.FullName -DestinationPath $Destination -Force -ErrorAction Stop
            Write-Host "Extracted: $($archive.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed: $($archive.Name)" -ForegroundColor Yellow
            Write-Host " → $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
}

function Invoke-YTDownloader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [ValidateSet("Raw", "VideoMP4", "VideoMKV", "AudioMP3", "AudioOpus", "AudioWAV")]
        [string]$Format = "Raw",

        [string]$OutputDir,

        [switch]$AllowPlaylist,

        [switch]$GetSubtitles
    )

    # Ensure yt-dlp exists
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Host "yt-dlp is not installed or not found in PATH." -ForegroundColor Red
        return
    }

    # Output directory
    if (-not $OutputDir) {
        $Shell = New-Object -ComObject Shell.Application
        $DownloadsDir = $Shell.NameSpace('shell:Downloads').Self.Path
        $OutputDir = "$DownloadsDir\YTDownloads"
    }

    # Ensure output directory exists
    if (-not (Test-Path $OutputDir)) {
        try {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Host "Failed to create output directory: $OutputDir" -ForegroundColor Red
            return
        }
    }

    # Confirm if playlist and not explicitly allowed
    if ($Url -match "list=" -and -not $AllowPlaylist) {
        $resp = Read-Host "This looks like a playlist. Download all items? [y/N]"
        if ($resp -notin @("y", "Y", "yes", "Yes")) {
            Write-Host "Aborted: Playlist not downloaded." -ForegroundColor Yellow
            return
        }
    }


    $Arguments = @(
        "--quiet"
        "--no-warnings"
        "--embed-metadata"
        "--output", "$OutputDir/%(title)s.%(ext)s"
        "--no-overwrites"
        "--progress"
    )

    # Subtitles
    if ($GetSubtitles) {
        $Arguments += "--write-subs"
        $Arguments += "--write-auto-subs"
        $Arguments += "--sub-lang"
        $Arguments += "en"
    }

    # Format switch with yt-dlp presets or custom
    switch ($Format) {
        "VideoMP4" { $Arguments += "-t"; $Arguments += "mp4"; $Arguments += "--embed-thumbnail" }
        "VideoMKV" { $Arguments += "-t"; $Arguments += "mkv"; $Arguments += "--embed-thumbnail" }
        "AudioMP3" { $Arguments += "-t"; $Arguments += "mp3"; $Arguments += "--embed-thumbnail" }

        "AudioOpus" {
            $Arguments += "--format"; $Arguments += "bestaudio"
            $Arguments += "--extract-audio"
            $Arguments += "--audio-format"; $Arguments += "opus"
        }

        "AudioWAV" {
            $Arguments += "--format"; $Arguments += "bestaudio"
            $Arguments += "--extract-audio"
            $Arguments += "--audio-format"; $Arguments += "wav"
        }

        "Raw" {
            $Arguments += "--format"; $Arguments += "bv+ba/b"
        }
    }

    # Run yt-dlp with arguments
    Write-Host "Downloading content to $OutputDir" -ForegroundColor DarkGray
    & yt-dlp @Arguments $Url
}



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
Usage: Search [Provider] <query>
Search the web using a specified search engine.

Search Providers:
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
    - If more than one search provider is specified, the first valid provider is used.
    - Default search engine can be set with the `$env:DEFAULT_SEARCH_ENGINE environment variable.
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
    $SelectedEngine = if ($ValidKeys.Count -gt 0) {
        ($ValidKeys[0] -as [string]).ToLower()
    }
    elseif ($env:DEFAULT_SEARCH_ENGINE -and $Engines.ContainsKey($env:DEFAULT_SEARCH_ENGINE)) {
        $env:DEFAULT_SEARCH_ENGINE
    }
    else {
        "duckduckgo"
    }

    # Validate the selected engine, exit if invalid
    if (-not $Engines.ContainsKey($SelectedEngine)) {
        Write-Error "Unsupported search engine: '$SelectedEngine'. Supported engines are: $($Engines.Keys -join ', ')"
        return
    }

    # Ensure a query is provided, else warn & exit
    if (-not $Query -or $Query.Count -eq 0) {
        Write-Host "No search query provided, please enter something to search for." -ForegroundColor Yellow
        return
    }

    # Build and launch the search URL
    $SearchQuery = $Query -join " "
    $SearchURL = $Engines[$SelectedEngine] + [uri]::EscapeDataString($SearchQuery)
    Start-Process $SearchURL
}

# Aliases for search operations
function s { Search @args }

# SETUP CLI TOOLS =================================

# Setup bat (alternative to cat)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    $ENV:BAT_CONFIG_PATH = "$ENV:USERPROFILE/.config/bat/bat.conf"
    $ENV:BAT_CONFIG_DIR = "$ENV:USERPROFILE/.config/bat"
    Set-Alias -Name cat -Value bat
}
else {
    Set-Alias -Name cat -Value Get-Content
    $StartupLogs += "Unable to find bat (https://github.com/sharkdp/bat) [using Get-Content]"
}

# Setup eza (alternative to ls/Get-ChildItem)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    # Set the config directory
    $env:EZA_CONFIG_DIR = "$env:USERPROFILE\.config\eza"
    # Remove the default ls alias
    Remove-Alias -Name ls -ErrorAction SilentlyContinue
    # Define command aliases for file & directory listings
    function ls { eza --no-permissions --long --all --no-quotes --group-directories-first --icons --time-style '+%h %d %H:%M' @args }
    function lt { eza --no-permissions --long --all --no-quotes --group-directories-first --icons --time-style '+%h %d %H:%M' --tree @args }
}
else {
    $StartupLogs += "Unable to find eza locally installed (https://github.com/eza-community/eza)"
}

# Setup fd (alternative to find)
if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:LS_COLORS = @(
        "di=34",          # Directory → Blue (standard fg: blue)
        "ln=36",          # Symlink → Cyan (standard fg: cyan)
        "so=35",          # Socket → Magenta (light use)
        "pi=33",          # Named pipe → Yellow (neutral)
        "ex=32",          # Executable → Green (safe/action-oriented)
        "bd=1;33",        # Block device → Bold yellow (device = caution)
        "cd=1;33",        # Char device → Same as above
        "su=30;41",       # setuid → Black on red (security-sensitive)
        "sg=30;43",       # setgid → Black on yellow (slightly less critical)
        "tw=30;42",       # sticky + other-writable → Black on green (writable)
        "ow=34;42",       # other-writable → Blue on green
        "st=37;44",       # sticky → White on blue
        "mi=05;37;41",    # missing → Dim white on red bg (broken link)
        "or=05;31;40",    # orphan → Dim red on black
        "no=0"            # default → Reset/normal
    ) -join ":"

    function ff { fd @args }
}
else {
    $StartupLogs += "Unable to find fd (https://github.com/sharkdp/fd)"
}


# Invoke FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    # Display FastFetch Output on Screen
    & fastfetch.exe
}
else {
    # Log the failure message
    $StartupLogs += "Unable to find fastfetch (https://github.com/fastfetch-cli/fastfetch)"
}

# Invoke Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {
    # Set up Environment Variables for Starship
    $ENV:STARSHIP_CONFIG = "$ENV:USERPROFILE/.config/starship/starship.toml"
    # Triggers PowerShell to use Startship Prompt
    Invoke-Expression (&starship init powershell)
}
else {
    # Log the failure message
    $StartupLogs += "Unable to find starship (https://starship.rs/)"
}

# Setup Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    # Activate Zoxide
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}
else {
    $StartupLogs += "Unable to find zoxide (https://github.com/ajeetdsouza/zoxide)"
}

# RESPORTING & CLOSURE ===============================

if ($StartupLogs.Count -gt 0) {
    Write-Host "`nStartup Failures:" -ForegroundColor Red
    $StartupLogs | ForEach-Object { Write-Host "`t- $($_)" }
}
