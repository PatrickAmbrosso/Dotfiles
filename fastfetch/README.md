# Configuration for the `fastfetch` command-line tool

This directory contains the configuration file for the `fastfetch` command-line tool.

## Usage

Copy the `config.jsonc` file to the `%USERPROFILE%\.config\fastfetch` directory. Make sure to point to this directory in the powershell profile.

```powershell
    $ENV:STARSHIP_CONFIG = "$ENV:USERPROFILE/.config/starship/starship.toml"
```