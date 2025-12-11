# Vocabulary Plus - Updates
Vocabulary Plus is regularly updated. Below is a list of recent updates (v1.0.0 to v1.1.0).

## v1.0.0
Released: 29th November 2025
### All Python files
- Added coloured output with `colorama`
### Main
- Added waiting
- Added printing of Vocabulary Plus version as well as Python version
### Installation Scripts
- You can now run Vocabulary Plus with the `vocabularyplus` command in your terminal.    
Use `vocabularyplus create` to create a vocabulary file.
- Now deletes requirements.txt after installation

## v1.0.1
Released: 30th November 2025
### Create Vocab File
- Made colours consistent
- Properly implemented `KeyboardInterrupt` handling
- System information print edited to align with Main
### Installation Scripts
- Added version print
#### Windows Installer
- Changed accidental use of 'color' to 'colour'
### Markdown Descriptions
- Renamed UPDATES.md to updates.md
- Edited link to updates in README

## v1.0.2
Released: 7th December 2025
### Python scripts
- Changed blue colour to light cyan for easy readability on a black background
### Installation Scripts
- Added new `vp` alias for the `vocabularyplus` command

## v1.1.0
Released: 11th December 2025
### Main
- Added a summary of the questions answered which shows after Ctrl+C.
### Installation Scripts
- Added creation of a desktop app icon which runs the main app.   
    <ins>Methods</ins>
    - **Linux:** .desktop file
    - **macOS:** .app bundle
    - **Windows:** .lnk file
- Added an uninstallation script. See [README](README.md) for how to run
### README
- Edited running instructions
- Edited method of installation for Unix
- Added instructions on uninstallation