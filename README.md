# Vocabulary Plus

![The Vocabulary Plus logo with the words 'Vocabulary Plus' to the right of it](https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main/icons/icon_large.png)

A Python-based foreign vocabulary learning tool.  
[View updates](UPDATES.md)

> [!WARNING]
> **Vocabulary Plus 2.0.0 is currently in Beta.**
>
> This version is still under development and may contain bugs, incomplete features, or breaking changes.
>
> If you encounter any problems, please report them in [GitHub Issues](https://github.com/46Dimensions/VocabularyPlus/issues)
>
> If you need a more stable experience, consider using the latest stable release (1.5.1) instead.

## Installation

Run these commands in your terminal,
replacing `<tag_name>` with the version of Vocabulary Plus
that you want to install (e.g. `v2.0.0-beta1`).

### Windows

[![Windows setup script](https://github.com/46Dimensions/VocabularyPlus/actions/workflows/windows-setup.yml/badge.svg)](https://github.com/46Dimensions/VocabularyPlus/actions/workflows/windows-setup.yml)

_Run in **PowerShell** (part of **Terminal**)_

``` powershell
# Download the ZIP file
Invoke-WebRequest -Uri "https://github.com/46Dimensions/VocabularyPlus/releases/download/<tag_name>/VocabularyPlus.zip" -OutFile .\VocabularyPlus.zip

# Unpack the ZIP file
Expand-Archive -Path ".\VocabularyPlus.zip" -DestinationPath "VocabularyPlus" -Force

# Move into the VocabularyPlus directory
Set-Location -Path "VocabularyPlus\installation\Windows"

# Allow the script to run without affecting ExecutionPolicy
Unblock-File -Path .\setup.ps1

# Run the file
& .\setup.ps1
```

### MacOS

[![MacOS setup script](https://github.com/46Dimensions/VocabularyPlus/actions/workflows/macos-setup.yml/badge.svg)](https://github.com/46Dimensions/VocabularyPlus/actions/workflows/macos-setup.yml)

_Run in the **Terminal** app._

``` shell
# Download the ZIP file showing a progress bar
wget -nv --show-progress -O vocabularyplus.zip "https://github.com/46Dimensions/VocabularyPlus/releases/download/<tag_name>/VocabularyPlus.zip"

# Unpack the ZIP file
unzip -o VocabularyPlus.zip -d VocabularyPlus

# Move into the VocabularyPlus directory
cd VocabularyPlus/installation/MacOS

sh setup.sh
```

### Linux

[![MacOS setup script](https://github.com/46Dimensions/VocabularyPlus/actions/workflows/linux-setup.yml/badge.svg)](https://github.com/46Dimensions/VocabularyPlus/actions/workflows/linux-setup.yml)

_Run in the **Terminal** app. The exact name can vary._

``` shell
# Download the ZIP file showing a progress bar
wget -nv --show-progress -O vocabularyplus.zip "https://github.com/46Dimensions/VocabularyPlus/releases/download/<tag_name>/VocabularyPlus.zip"

# Unpack the ZIP file
unzip -o VocabularyPlus.zip -d VocabularyPlus

# Move into the VocabularyPlus directory
cd VocabularyPlus/installation/MacOS

sh setup.sh
```

## Uninstallation

_Run in **PowerShell** on Windows; **Terminal** on macOS or Linux (name may vary)._

``` shell
vocabularyplus uninstall
```

## Running the script

Run `vocabularyplus` or `vp`, or use the Vocabulary Plus app.

## Using Vocabulary Plus Version Manager

See [`vp-vm`'s README](https://github.com/46Dimensions/vp-vm/blob/main/README.md) for usage instructions.

## Reporting bugs

Go to [Create New Issue](https://github.com/46Dimensions/VocabularyPlus/issues/new).
For more information, see [Contributing](CONTRIBUTING.md).

## License

Licensed under the MIT License — see [LICENSE](LICENSE) for details.

## Text icon help

If the text logo, shown when you run a VocabularyPlus command, is not working, your terminal or font
does not support Unicode 13.0's [Symbols for Legacy Computing](https://en.wikipedia.org/wiki/Symbols_for_Legacy_Computing).

Solutions:

- Windows: Use Windows Terminal
- MacOS and Linux: Update your OS
- Use a different font
