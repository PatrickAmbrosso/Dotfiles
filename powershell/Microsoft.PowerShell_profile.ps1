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

# UTILITY FUNCTIONS =================================
function export {
    param(
        [Parameter(Position = 0, Mandatory = $true)] [string]$name,
        [Parameter(Position = 1, Mandatory = $true)] [string]$value
    )
    set-item -force -path "env:$name" -value $value
}
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
function mkcd { 
    param($dir) 
    
    New-Item -ItemType Directory -Force -Path $dir | Out-Null ; Set-Location $dir
}
function fcd {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "fzf is not installed or not found in PATH. Needed for fcd." -ForegroundColor Red
        return
    }

    $dir = Get-ChildItem -Directory -Recurse -EA SilentlyContinue | 
    Select-Object -ExpandProperty FullName | 
    fzf --height 40% --border=rounded --margin=1, 0 --reverse --prompt="Search Directories: " --ghost="Type to search for directories/folders"  --highlight-line --color=16
    if ($dir) { Set-Location $dir }
}
function ff {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "fzf is not installed or not found in PATH. Needed for ff." -ForegroundColor Red
        return
    }

    $file = Get-ChildItem -Recurse -File -EA SilentlyContinue | 
    Select-Object -ExpandProperty FullName | 
    fzf --height 40% --border=rounded --margin=1, 0 --reverse --prompt="Search Files: " --ghost="Type to search for files"  --highlight-line --color=16
    if ($file) {
        if ($NoHyperLinks) {
            Write-Host "Selected: $file"
        }
        else {
            $esc = [char]27
            $link = "${esc}]8;;file:///$file`a$file${esc}]8;;`a"
            Write-Host "Selected: $link"
        }
    }
}
function fps {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning "fzf is not installed or not found in PATH."
        return
    }

    $procs = Get-Process | Sort-Object ProcessName
    $displayList = $procs | ForEach-Object {
        "{0,-8}  {1}" -f $_.Id, $_.ProcessName
    }

    $selection = $displayList | fzf --height 40% --border=rounded --reverse --multi --prompt="Search Process: " --ghost="Type to search for processes" --highlight-line --color=16

    if ($selection) {
        # $selection is a single string with one or more lines
        $ProcessIDs = $selection -split "`n" | ForEach-Object { ($_ -split '\s+')[0] }
        foreach ($id in $ProcessIDs) {
            $procObj = $procs | Where-Object { $_.Id -eq [int]$id }
            if ($procObj) { $procObj }
            else { Write-Warning "Process $id not found." }
        }
    }
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
function which {
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
function extract {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string[]]$Pattern,
        [string]$Destination = $PWD
    )

    function Get-Extractor($file) {
        $lc = $file.ToLowerInvariant()
        switch -regex ($lc) {
            '\.(zip|tar|gz|tgz|bz2|tar\.gz|tar\.bz2|xz|tar\.xz)$' { "tar" }
            '\.(7z|rar)$' { "7z" }
            default { $null }
        }
    }

    function Assert-ToolAvailable($tool) {
        switch ($tool) {
            "tar" { Get-Command tar.exe -ErrorAction SilentlyContinue }
            "7z" { Get-Command 7z.exe  -ErrorAction SilentlyContinue }
            default { $false }
        }
    }

    $archives = foreach ($p in $Pattern) {
        Resolve-Path $p -ErrorAction SilentlyContinue | Get-Item
    }

    if (-not $archives) {
        Write-Host "No matching archives found." -ForegroundColor Red
        return
    }

    if (-not (Test-Path $Destination)) {
        try { New-Item -Path $Destination -ItemType Directory -Force | Out-Null }
        catch {
            Write-Host "Failed to create directory: $Destination" -ForegroundColor Red
            return
        }
    }

    foreach ($archive in $archives | Sort-Object -Unique FullName) {
        $full = $archive.FullName
        $tool = Get-Extractor $full
        if (-not $tool) {
            Write-Host "No extractor for: $($archive.Name)" -ForegroundColor Yellow
            continue
        }
        if (-not (Assert-ToolAvailable $tool)) {
            Write-Host "'$tool' not available for $($archive.Name)" -ForegroundColor Yellow
            continue
        }
        try {
            switch ($tool) {
                "tar" { & tar -xf $full -C $Destination }
                "7z" { & 7z x $full "-o$Destination" -y | Out-Null }
            }
            Write-Host "Extracted: $($archive.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed: $($archive.Name)" -ForegroundColor Yellow
        }
    }
}
function cleanup {
    function Write-Status {
        param (
            [string]$Message
        )
        Write-Host "`r$Message" -ForegroundColor DarkGray -NoNewline
        Start-Sleep -Milliseconds 300
    }

    Write-Status "Clearing IE Cache"
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -EA SilentlyContinue

    Write-Status "Clearing User Temp Files"    
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue

    Write-Status "Clearing Windows Temp Files"
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -EA SilentlyContinue

    Write-Host "`rCache & Temporary files have been cleared." -ForegroundColor Blue
}
function ytdl {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)][string]$Url,
        [ValidateSet("Raw", "VideoMP4", "VideoMKV", "AudioMP3", "AudioOpus", "AudioWAV")][string]$Format = "Raw",
        [string]$OutputDir,
        [switch]$AllowPlaylist,
        [switch]$GetSubtitles,
        [switch]$Help
    )

    if ($Help) {
        Write-Host @"
Usage:
    YTdl <Url> [options]

Description:
    Download YouTube videos or audio using yt-dlp.

Arguments:
    <Url>           YouTube video or playlist URL (required).

Options:
    -Format         Output format. Default: VideoMP4.
    -OutputDir      Directory to save downloads.
    -AllowPlaylist  Download all videos if URL is a playlist.
    -GetSubtitles   Download English subtitles if available.
    -Help           Show this help message.

Notes:
    - yt-dlp and ffmpeg must be installed and available in PATH.
    - Available formats: VideoMP4, VideoMKV, AudioMP3, AudioOpus, AudioWAV.
    - Playlists require confirmation unless -AllowPlaylist is specified.
    - Subtitles (if requested) are English only.
"@
        return
    }

    if (-not $Url) {
        Write-Host "Error: Url is required. Use -Help for usage details." -ForegroundColor Red
        return
    }

    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Host "yt-dlp is not installed or not found in PATH." -ForegroundColor Red
        return
    }

    if (-not $OutputDir) {
        $Shell = New-Object -ComObject Shell.Application
        $DownloadsDir = $Shell.NameSpace('shell:Downloads').Self.Path
        $OutputDir = "$DownloadsDir\YTDownloads"
    }

    if (-not (Test-Path $OutputDir)) {
        try {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Host "Failed to create output directory: $OutputDir" -ForegroundColor Red
            return
        }
    }

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

    if ($GetSubtitles) {
        $Arguments += "--write-subs"
        $Arguments += "--write-auto-subs"
        $Arguments += "--sub-lang"
        $Arguments += "en"
    }

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

    Write-Host "Downloading content to $OutputDir" -ForegroundColor DarkGray
    & yt-dlp @Arguments $Url
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "Download completed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Download failed with exit code $exitCode." -ForegroundColor Red
    }
}
function yank {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location),
    
        [switch]$Content,
        [switch]$Command,
        [switch]$Help    
    )

    if ($Help) {
        Write-Host @"
Usage:
    Yank [-Content] <Path>
    Yank -Command

Description:
    Copy path, previous command, or file content to clipboard.

Arguments:
    <Path>     File or directory path. Defaults to current directory.

Options:
    -Content   Copy the file contents to clipboard (files only).
    -Command   Copy the previous shell command to clipboard.
    -Help      Show this help message.

Examples:
    Yank
    Yank -Content C:\example.txt
    Yank -Command

Notes:
    - Without any switches, the current or specified path is copied.
    - Option -Content copies the file content (dirs not supported).
    - The option -Command uses shell history.
"@
        return
    }

    if ($Command) {
        $prevCmd = (Get-History -Count 1 | Select-Object -ExpandProperty CommandLine)
        if ($null -eq $prevCmd) {
            Write-Host "No previous command found in history." -ForegroundColor Yellow
        }
        else {
            Set-Clipboard -Value $prevCmd
            Write-Host "Previous command copied to clipboard."
        }
        return
    }

    if (-not (Test-Path $Path)) {
        Write-Host "Path '$Path' does not exist." -ForegroundColor Red
        return
    }

    $FullPath = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path

    if ($Content) {
        if (Test-Path $Path -PathType Container) {
            Write-Host "Cannot copy content of a directory. Path is a directory." -ForegroundColor Yellow
            return
        }
        Set-Clipboard -Value (Get-Content -Path $FullPath -Raw)
        Write-Host "File content copied to clipboard."
        return
    }

    # Default: Copy path
    Set-Clipboard -Value $FullPath
    Write-Host "Path copied to clipboard: $FullPath"
}
function search {

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
function grab {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Source,
        [string]$OutputDir,
        [int]$Connections = 8
    )

    # Check for aria2c
    $aria = Get-Command "aria2c" -ErrorAction SilentlyContinue
    if (-not $aria) {
        Write-Host "aria2c is not installed or not found in PATH!" -ForegroundColor Red
        return
    }

    # Detect source type
    $isTorrent = ($Source -like "*.torrent") -or (Test-Path $Source -PathType Leaf -and ($Source -match "\.torrent$"))
    $isMagnet = $Source -like "magnet:*"
    $isHttp = $Source -match '^https?://'

    if (-not ($isTorrent -or $isMagnet -or $isHttp)) {
        Write-Host "Unsupported source: $Source" -ForegroundColor Red
        return
    }

    # Decide on OutputDir
    if (-not $OutputDir) {
        $Shell = New-Object -ComObject Shell.Application
        $downloads = $Shell.NameSpace('shell:Downloads').Self.Path

        if ($isHttp -or $isTorrent) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($Source)
        }
        elseif ($isMagnet) {
            # Use first 8 of hash as folder
            if ($Source -match "btih:([a-fA-F0-9]+)") {
                $name = "magnet-" + $matches[1].Substring(0, 8)
            }
            else {
                $name = "magnet-download"
            }
        }
        $OutputDir = Join-Path $downloads $name
    }

    # Ensure OutputDir exists
    if (-not (Test-Path $OutputDir -PathType Container)) {
        try {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Host "Failed to create output directory: $OutputDir" -ForegroundColor Red
            return
        }
    }

    # Compose aria2c arguments
    $ariaArgs = @(
        "-x $Connections"
        "-s $Connections"
        "-d `"$OutputDir`""
        "--console-log-level=warn"
        "--summary-interval=0"
        "`"$Source`""
    )

    if ($isTorrent -or $isMagnet) {     
        $ariaArgs += "--seed-time=0"
    }

    Write-Host "`nDownloading to $OutputDir" -ForegroundColor Blue
    $cmd = "aria2c $($ariaArgs -join ' ')"
    Invoke-Expression $cmd
}
function .. { Set-Location .. }
function ... { Set-Location ..\.. }


# SETUP CLI TOOLS ================================

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

# Check fzf exists
if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    $StartupLogs += "Unable to find fzf (needed for fuzzy ops) (https://github.com/junegunn/fzf)"
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

# Invoke FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    # Display FastFetch Output on Screen
    & fastfetch.exe
}
else {
    # Log the failure message
    $StartupLogs += "Unable to find fastfetch (https://github.com/fastfetch-cli/fastfetch)"
}

# Setup Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    # Activate Zoxide
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}
else {
    $StartupLogs += "Unable to find zoxide (https://github.com/ajeetdsouza/zoxide)"
}

# RESPORTING & CLOSURE ===========================

if ($StartupLogs.Count -gt 0) {
    Write-Host "`nStartup Failures:" -ForegroundColor Red
    $StartupLogs | ForEach-Object { Write-Host "`t- $($_)" }
}

# Set up ENV VARS ================================
$env:UV_LINK_MODE = "copy" # uv option
