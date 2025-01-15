# Configuration for the `starship` prompt

This directory contains the configuration file for the `starship` prompt.

## Usage

Copy the `starship.toml` file to the `%USERPROFILE%\.config\starship` directory. Make sure to point to this directory in the powershell profile.

```powershell
    $ENV:STARSHIP_CONFIG = "$ENV:USERPROFILE/.config/starship/starship.toml"
```