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

Vocabulary Plus should be installed with its dedicated version management tool, Vocabulary Plus Version Manager (`vp-vm`).

You can get VP VM and install the latest Vocabulary Plus version with the commands below.

More information about VP VM can be found on [its website](https://github.com/46Dimensions/vp-vm).

### Windows

Run in **Windows Terminal** > **PowerShell**

``` powershell
# Download the installation script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/46Dimensions/vp-vm/2.0.0/install.ps1" -OutFile ".\install.ps1"

# Run the script then remove it
& .\install.ps1
Remove-Item -Force -Path .\install.ps1

# Install the latest Vocabulary Plus version
vp-vm install latest

# Make the version active
vp-vm use latest
```

### MacOS/Linux

Run in **Terminal** (name may vary)

``` shell
# Download and immediately run the installation script
curl -fsSL "https://raw.githubusercontent.com/46Dimensions/vp-vm/2.0.0/install.sh" | sh

# Install the latest Vocabulary Plus version
vp-vm install latest

# Make the version active
vp-vm use latest
```

## Running Vocabulary Plus
Run `vocabularyplus` or `vp`, or use the Vocabulary Plus app.

## Reporting bugs

Go to [Create New Issue](https://github.com/46Dimensions/VocabularyPlus/issues/new).
For more information, see [Contributing](CONTRIBUTING.md).

## License

Licensed under the MIT License — see [LICENSE](LICENSE) for details.

## Text icon help

If the text logo, shown when you open Vocabulary Plus, is not working, your terminal or font does not support Unicode 13.0's [Symbols for Legacy Computing](https://en.wikipedia.org/wiki/Symbols_for_Legacy_Computing).

Solutions:

- Windows: Use Windows Terminal
- MacOS and Linux: Update your OS
- Use a different font
