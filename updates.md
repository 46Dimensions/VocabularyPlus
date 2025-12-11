# Vocabulary Plus - Updates
Vocabulary Plus is regularly updated. Below is a list of recent updates (v1.0.0 to v1.2.0).

## v1.0.0
Released: 29th November 2025
### All Python files
- Added coloured output with `colorama`
### [Main](main.py)
- Added waiting
- Added printing of Vocabulary Plus version as well as Python version
### Installation Scripts
- You can now run Vocabulary Plus with the `vocabularyplus` command in your terminal.    
Use `vocabularyplus create` to create a vocabulary file.
- Now deletes requirements.txt after installation

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.0.0)

## v1.0.1
Released: 30th November 2025
### [Create Vocab File](create_vocab_file.py)
- Made colours consistent
- Properly implemented `KeyboardInterrupt` handling
- System information print edited to align with Main
### Installation Scripts
- Added version print
#### Windows Installer
- Changed accidental use of 'color' to 'colour'
### Markdown Descriptions
- Renamed UPDATES.md to [updates.md](updates.md)
- Edited link to updates in [README](README.md)

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.0.1)

## ~~v1.0.2~~
**IMPORTANT!!! This version has broken the Semantic Versioning rules. It should be v1.1.0. If you have installed this version, install the latest version as soon as possible.**   
Released: 7th December 2025   
### Python scripts
- Changed blue colour to light cyan for easy readability on a black background
### Installation Scripts
- Added new `vp` alias for the `vocabularyplus` command

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.0.2)

## v1.1.0
Released: 11th December 2025
### [Main](main.py)
- Added a summary of the questions answered which shows after Ctrl+C.
### Installation Scripts
- Added creation of a desktop app icon which runs the main app.   
    <ins>Methods</ins>
    - **Linux:** .desktop file
    - **macOS:** .app bundle
    - **Windows:** .lnk file
- Added creation of an uninstallation script. Run it with `vocabularyplus uninstall`
### [README](README.md)
- Edited running instructions
- Edited installation command for Unix
- Added instructions on uninstallation

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.1)

## v1.2.0
Released: 11th December 2025
### Terminal Commands
- Added flags
    - `--help`
    - `--version`
- Added subcommand `uninstall`
### Installation Scripts
- Added download of [README](README.md)
### Other
- Added [contribution instructions](CONTRIBUTING.md).

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.2.0)