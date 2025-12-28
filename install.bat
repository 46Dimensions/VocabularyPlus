@echo off
setlocal ENABLEDELAYEDEXPANSION

:: Enable ANSI escape sequences (Windows 10+ only)
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "red=%ESC%[91m"
set "green=%ESC%[92m"
set "yellow=%ESC%[93m"
set "cyan=%ESC%[1;96m"
set "reset=%ESC%[0m"

echo %cyan%===============================================%reset%
echo %cyan%Vocabulary Plus: Windows Installer (1.3.0)%reset%
echo %cyan%===============================================%reset%
echo.

:: Windows 10+ Check
for /f "tokens=4-5 delims=. " %%a in ('ver') do (
    set MAJOR=%%a
)

if "%MAJOR%" LSS "10" (
    echo %red%ERROR: Windows 10 or later is required.%reset%
    echo Detected version: %MAJOR%
    exit /b 1
)

:: Python Check
where python >nul 2>&1
if errorlevel 1 (
    echo %red%ERROR: Python not found. Please install Python 3.10+.%reset%
    exit /b 1
)

for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set PYVER=%%v
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set MAJORPY=%%a
    set MINORPY=%%b
)

if %MAJORPY% LSS 3 (
    echo %red%ERROR: Python must be >= 3.10 (found %PYVER%).%reset%
    exit /b 1
)
if %MAJORPY% EQU 3 if %MINORPY% LSS 10 (
    echo %red%ERROR: Python must be >= 3.10 (found %PYVER%).%reset%
    exit /b 1
)

:: Check if Vocabulary Plus is already installed
set "COMMAND_NAME=vocabularyplus.cmd"
where %COMMAND_NAME% >nul 2>&1
if not errorlevel 1 (
    echo %red%ERROR: Vocabulary Plus appears to be already installed.%reset%
    exit /b 1
)

:: Paths + download URLs
set "BASE_URL=https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/1.3.0"
set "REQ_URL=%BASE_URL%/requirements.txt"
set "1.3.0_URL=%BASE_URL%/main.py"
set "CREATE_URL=%BASE_URL%/create_vocab_file.py"
set "ICON_URL=%BASE_URL%/app_icon.png"
set "VP_VM_INSTALLER_URL=https://raw.githubusercontent.com/46Dimensions/vp-vm/main/install-vm.bat"

set "INSTALL_DIR=%CD%\VocabularyPlus"

echo %yellow%Creating VocabularyPlus directory at %INSTALL_DIR%...%reset%
mkdir "%INSTALL_DIR%" >nul 2>&1
cd "%INSTALL_DIR%" || (echo %red%Failed to enter VocabularyPlus directory%reset% & exit /b 1)

:: Download files
echo %yellow%Downloading files...%reset%
curl -fsSL "%REQ_URL%" -o requirements.txt || (echo %red%Failed to download requirements.txt%reset% & exit /b 1)
curl -fsSL "%MAIN_URL%" -o main.py || (echo %red%Failed to download main.py%reset% & exit /b 1)
curl -fsSL "%CREATE_URL%" -o create_vocab_file.py || (echo %red%Failed to download create_vocab_file.py%reset% & exit /b 1)
curl -fsSL "%ICON_URL%" -o app_icon.png || (echo %red%Failed to download icon%reset% & exit /b 1)

:: Virtual environment
echo %yellow%Creating virtual environment...%reset%
python -m venv venv || (echo %red%Failed to create venv%reset% & exit /b 1)

set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"

:: Upgrade pip
echo %yellow%Upgrading pip...%reset%
"%PY%" -m pip install --upgrade pip

:: Install dependencies
echo %yellow%Installing dependencies...%reset%
"%PY%" -m pip install -r requirements.txt
del requirements.txt

:: Create launcher
set "BIN_DIR=%USERPROFILE%\AppData\Local\Programs\VocabularyPlus"
mkdir "%BIN_DIR%" >nul 2>&1

set "LAUNCHER=%BIN_DIR%\vocabularyplus.cmd"

echo %yellow%Creating launcher at %LAUNCHER%...%reset%

(
echo @echo off
echo set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"
echo set "APPDIR=%INSTALL_DIR%"
echo.
:: Help option
echo if "%%1"=="--help" (
    echo echo.
    echo echo "Usage: vocabularyplus [create] [options]"
    echo echo "Commands:"
    echo echo "  create        Create a new vocabulary file"
    echo echo "  uninstall     Uninstall Vocabulary Plus"
    echo echo "Options:"
    echo echo "  -v, --version   Show version information"
    echo echo "  --help          Show this help message"
    echo echo "Alias:"
    echo echo "  vp            Shortcut for vocabularyplus"
    exit /b 0
)
echo.
:: Version option
if "%1"=="--version" (
  echo 1.3.0
) else if "%1"=="-v" (
  echo 1.3.0
)
echo.
:: Handle "uninstall" subcommand
echo if "%%1"=="uninstall" (
echo     echo %yellow%Starting uninstallation...%reset%
echo     "%%APPDIR%%\uninstall.cmd"
echo     exit /b 0
echo ) 
echo.
:: Handle "create" subcommand
echo if "%%1"=="create" (
echo     shift
echo     "%%PY%%" "%%APPDIR%%\create_vocab_file.py" %%%%*
echo ) else (
echo     "%%PY%%" "%%APPDIR%%\main.py" %%%%*
echo )
echo.
) > "%LAUNCHER%"
echo %green%Launcher created successfully.%reset%

:: Create alias "vp"
echo @echo off ^& "%LAUNCHER%" %%* > "%BIN_DIR%\vp.cmd"

:: Create uninstall script
set "UNINSTALLER=%INSTALL_DIR%\uninstall.cmd"
echo %yellow%Creating uninstaller script at %UNINSTALLER%...%reset%

(
echo @echo off
echo setlocal ENABLEDELAYEDEXPANSION

echo echo %green%=================================================%reset%
echo echo %green%Vocabulary Plus: Windows Uninstaller (1.3.0)%reset%
echo echo %green%=================================================%reset%
echo echo.

echo echo %yellow%Removing VocabularyPlus installation...%reset%

echo cd "%INSTALL_DIR%" ^>nul 2^>^&1
echo if not %%errorlevel%%==0 (
echo ^    echo %red%Failed to enter VocabularyPlus directory%reset%
echo ^    exit /b 1
echo )

echo :: Remove files
echo del /q main.py 2^>nul
echo del /q create_vocab_file.py 2^>nul
echo del /q app_icon.png 2^>nul
echo del /q requirements.txt 2^>nul

echo :: Remove directories
echo rmdir /s /q JSON 2^>nul
echo rmdir /s /q venv 2^>nul

echo echo %green%VocabularyPlus files and directories removed.%reset%

echo echo %yellow%Removing launchers...%reset%

echo del /q "%USERPROFILE%\AppData\Local\Programs\VocabularyPlus\vocabularyplus.cmd" 2^>nul
echo del /q "%USERPROFILE%\AppData\Local\Programs\VocabularyPlus\vp.cmd" 2^>nul

echo echo %green%Launchers removed.%reset%

echo echo %yellow%Removing Start Menu shortcuts...%reset%

echo del /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk" 2^>nul
echo del /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\vp.lnk" 2^>nul

echo echo %green%Shortcuts removed.%reset%

echo echo.
echo echo %green%Uninstallation complete.%reset%
echo echo %yellow%If you found any issues, report them at https://github.com/46Dimensions/VocabularyPlus/issues %reset%

echo cd ..
echo rmdir /s /q "%INSTALL_DIR%" 2^>nul
echo del /q install.bat 2^>nul
) > "%UNINSTALLER%"

echo %green%Uninstaller created successfully.%reset%

:: Start Menu Shortcut
echo %yellow%Creating Start Menu shortcut...%reset%

set "SM_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
set "SHORTCUT=%SM_DIR%\Vocabulary Plus.lnk"

powershell -NoProfile -Command ^
    "$s=(New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT%');" ^
    "$s.TargetPath='%LAUNCHER%';" ^
    "$s.IconLocation='%INSTALL_DIR%\app_icon.png';" ^
    "$s.Save()"

echo %green%Start Menu shortcut created successfully.%reset%

:: Install Vocabulary Plus Version Manager
echo %yellow%Installing Vocabulary Plus Version Manager...%reset%
echo %yellow%Downloading installer...%reset%
curl -fsSL "%VP_VM_INSTALLER_URL%" -o install-vm.bat || (echo %red%Failed to download VP VM installer%reset% & exit /b 1)
echo %green%Download complete.%reset%
echo %yellow%Running VP VM installer...%reset%
call install-vm.bat "%INSTALL_DIR%\vm" || (echo %red%Failed to install VP VM%reset% & exit /b 1)
echo %green%VP VM installation complete.%reset%
del /q install-vm.bat

:: Create version directory and file if needed
if not exist "%INSTALL_DIR%\vm\versions\vp" mkdir "%INSTALL_DIR%\vm\versions\vp"
echo 1.3.0 > "%INSTALL_DIR%\vm\versions\vp\current.txt"

:: Final message
echo.
echo %green%Vocabulary Plus 1.3.0 installed successfully%reset%
echo.
echo You can run Vocabulary Plus with the following commands:
echo   vocabularyplus           main application
echo   vocabularyplus create    to create a new vocabulary file
echo   vp                       shortcut for main application
echo   vp create                shortcut to create a new vocabulary file
echo.
echo To use vp-vm (Vocabulary Plus Version Manager), see its help message:
echo   vp-vm --help
echo.
echo To uninstall Vocabulary Plus, run:
echo   vocabularyplus uninstall
echo.
echo If commands don't work, add this to PATH:
echo   %BIN_DIR%
echo.
