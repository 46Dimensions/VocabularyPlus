# VocabPy - Updates
VocabPy is regularly updated. Below is a list of recent updates.

## v1.1.0
Released: 19th November 2025
### Markdown Descriptions
- Updated `README.md`
- Added this `UPDATES.md`

### Main.py
#### Fixed some potential bugs when running on Windows:
- Added a fallback if the terminal does not support ANSI cursor movement
- Added output flush in `dynamic_input()` to prevent issues displaying text with `\r`.
- `file_path = Path(full_path).expanduser().resolve()` in `get_display_filename` edited to prevent a problem on Windows when using a network drive of symlink that the user lacks permission for.

#### UI changes:
- Now prints Python version and system information at start
- Moved the `Use CTRL+C to quit` message to just after printing the version info
- Added an underline beneath the VocabPy title lines

### Create Vocab File.py
#### Fixed Windows compatibility issues:
- Fixed an issue where the vocabulary file is not saved properly
- Simplified `.json` extension check to work with uppercase file extensions on Windows
- Added Windows reserved filename check
#### Other changes
- Made input stripping consistent in `check_input`

### Installation Scripts
- Added creation of a 'VocabPy' directory inside the working directory
- Added download of `create_vocab_file.py`
- Added Python check - aborts if Python is not installed or is below version 3.10.
- Now runs the script from inside the virtual environment
