# Vocabulary Plus - Updates

Vocabulary Plus is regularly updated. Below is a list of recent updates (v1.0.0 to v1.3.0 Beta).

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

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.0.0)

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

- Renamed UPDATES.md to [updates.md](updates.md)
- Edited link to updates in [README](README.md)

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.0.1)

## v1.1.0

Released: 11th December 2025

### Main

- Added a summary of the questions answered which shows after Ctrl+C.

### Installation Scripts

- Added creation of a desktop app icon which runs the main app.  

  _Methods_

  - **Linux:** `.desktop` file
  - **macOS:** `.app` bundle
  - **Windows:** `.lnk` file
- Added creation of an uninstallation script. Run it with `vocabularyplus uninstall`

### README

- Edited running instructions
- Edited installation command for Unix
- Added instructions on uninstallation

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.1)

## v1.2.0

Released: 15th December 2025

### Terminal Commands

- Added flags
  - `--help`
  - `--version`
- Added subcommand `uninstall`

### Installation Scripts

- Added download of [README](README.md)

### Other

- Added [contribution instructions](CONTRIBUTING.md).

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/1.2.0)

## v1.2.1

Released: 15th December 2025

### Uninstallation Script

- Fixed issue [#16](https://github.com/46Dimensions/VocabularyPlus/issues/16)

### Updates

- Patched some minor problems

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.2.1)

## v1.3.0 Beta

Released: 20th December 2025  
Version 1.3.0 is currently in Beta, so it is unstable.

### Installation Scripts

- Updated headers  

  #### Old headers

  _Unix_

  ``` text
  ====================================
  Vocabulary Plus Unix Installer 1.2.1
  ====================================
  ```

  _Windows_

  ``` text
  =======================================
  Vocabulary Plus Windows Installer 1.2.1
  =======================================
  ```

  #### New headers

  _macOS/Linux_

  ``` text
  ============================================
  Vocabulary Plus: Unix Installer (1.3.0 Beta)
  ============================================
  ```

  _Windows_

  ``` text
  ===============================================
  Vocabulary Plus: Windows Installer (1.3.0 Beta)
  ===============================================
  ```

- Updated colours
  - Headers are now bold high-intensity cyan.
  - All other colours are high-intensity as well

#### macOS/Linux Installer

- Added integration of [Vocabulary Plus Version Manager](https://github.com/46Dimensions/vp-vm) (`vp-vm`)
  - See [`vp-vm`'s README](https://github.com/46Dimensions/vp-vm/blob/main/README.md) for more information.
  - It will be available on Windows in 2026, in version 1.3.0.

### Version

- Added a `version.txt` file for use in `vp-vm`

### App Icon

- Changed the icon for the desktop app to

[![The Vocabulary Plus logo](https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/1.3.0/app_icon.png)](https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/1.3.0/app_icon.png)

### Markdown Documentation

- Improved syntax to comply with [markdownlint](https://github.com/DavidAnson/markdownlint) rules
  - Added a `.markdownlint.json` file to configure markdownlint

#### README

- Added the [Vocabulary Plus logo](/readme_icon.png) to the top of [the file](/README.md)

[_View on GitHub_](https://github.com/46Dimensions/VocabularyPlus/releases/v1.3.0-beta)

## v1.3.0 (Stable)

Released: 1st January 2026  
This version contains all of the changes from v1.3.0 Beta and some more (below).

### Windows Installer

- Added integration with Vocabulary Plus Version Manager

### Markdown

#### Images

- Images are now accessed via the web.

#### Update notes

- Renamed from updates.md to UPDATES.md

#### README

- Now no longer downloaded in installation scripts

### Version file

- Renamed from version.txt to VERSION.txt
