# Vocabulary Plus

![The Vocabulary Plus logo with the words 'Vocabulary Plus' to the right of it](https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/1.5.0/icons/icon_large.png)

A Python-based foreign vocabulary learning tool.  
[View updates](UPDATES.md)

## Installation

Run these commands in your terminal.
You must have Python 3.10+ installed.

### Windows

_Run in **PowerShell** (in Terminal app)_

``` powershell
# Download the file
Invoke-WebRequest -Uri https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main/install.ps1/ -OutFile .\install.ps1

# Allow the script to run without affecting ExecutionPolicy
Unblock-File -Path .\install.ps1

# Run the file
.\install.ps1
```

### macOS/Linux

_Run in the **Terminal** app. The exact name can vary._

``` shell
# Download the content and pipe it into sh to run instantly
curl -fsSL https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main/install.sh | sh
```

Or if you want to view the downloaded file before running:

``` shell
# Download the file
curl -fsSL https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main/install.sh -o install.sh

# View the file
nano install.sh

# Run the file then delete it
sh install.sh
rm install.sh
```

## Uninstallation

_Run in **PowerShell** on Windows; **Terminal** on macOS or Linux (name may vary)._

``` shell
vocabularyplus uninstall
```

## Running the script

Run `vocabularyplus` or `vp`.  
To make a vocabulary JSON file, run `vocabularyplus create` or `vp create`.  
To open the menu, use `vocabularyplus menu` or `vp menu`, or use the 'Vocabulary Plus' application.

## Using Vocabulary Plus Version Manager

See [`vp-vm`'s README](https://github.com/46Dimensions/vp-vm/blob/main/README.md) for usage instructions.

## Reporting bugs

Go to [Create New Issue](https://github.com/46Dimensions/VocabularyPlus/issues/new).
For more information, see [Contributing](CONTRIBUTING.md).

## License

Licensed under the MIT License — see [LICENSE](LICENSE) for details.
