@echo off
setlocal ENABLEDELAYEDEXPANSION

:: Enable ANSI escape sequences
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "red=%ESC%[91m"
set "green=%ESC%[92m"
set "yellow=%ESC%[93m"
set "cyan=%ESC%[1;96m"
set "reset=%ESC%[0m"

echo %cyan%==========================================%reset%
echo %cyan%Vocabulary Plus: Windows Installer (1.4.0)%reset%
echo %cyan%==========================================%reset%
echo.

:: Windows version check
for /f "tokens=4-5 delims=. " %%a in ('ver') do set MAJOR=%%a
if "%MAJOR%" LSS "10" (
    echo %red%ERROR: Windows 10 or later is required.%reset%
    exit /b 1
)

:: Python check
where python >nul 2>&1
if errorlevel 1 (
    echo %red%ERROR: Python not found. Install Python 3.10+.%reset%
    exit /b 1
)

for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set PYVER=%%v
for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set MAJORPY=%%a
    set MINORPY=%%b
)

if %MAJORPY% LSS 3 (
    echo %red%ERROR: Python must be >=3.10%reset%
    exit /b 1
)

if %MAJORPY% EQU 3 if %MINORPY% LSS 10 (
    echo %red%ERROR: Python must be >=3.10%reset%
    exit /b 1
)

:: Prevent reinstall
set "COMMAND_NAME=vocabularyplus.cmd"
where %COMMAND_NAME% >nul 2>&1
if not errorlevel 1 (
    echo %red%ERROR: Vocabulary Plus already appears installed.%reset%
    exit /b 1
)

:: URLs
set "BASE_URL=https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main"
set "REQ_URL=%BASE_URL%/requirements.txt"
set "MAIN_URL=%BASE_URL%/main.py"
set "CREATE_URL=%BASE_URL%/create_vocab_file.py"
set "ICON_URL=%BASE_URL%/app_icon.png"
set "VP_VM_INSTALLER_URL=https://raw.githubusercontent.com/46Dimensions/vp-vm/main/install-vm.bat"

:: Install directory
set "INSTALL_DIR=%CD%\VocabularyPlus"

echo %yellow%Creating install directory...%reset%
mkdir "%INSTALL_DIR%" >nul 2>&1
cd "%INSTALL_DIR%" || exit /b 1

:: Download files
echo %yellow%Downloading files...%reset%
curl -fsSL "%REQ_URL%" -o requirements.txt || exit /b 1
curl -fsSL "%MAIN_URL%" -o main.py || exit /b 1
curl -fsSL "%CREATE_URL%" -o create_vocab_file.py || exit /b 1
curl -fsSL "%ICON_URL%" -o app_icon.png || exit /b 1

:: Create venv
echo %yellow%Creating virtual environment...%reset%
python -m venv venv || exit /b 1

set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"

echo %yellow%Upgrading pip...%reset%
"%PY%" -m pip install --upgrade pip

echo %yellow%Installing dependencies...%reset%
"%PY%" -m pip install -r requirements.txt
del requirements.txt

:: Launcher directory
set "BIN_DIR=%USERPROFILE%\AppData\Local\Programs\VocabularyPlus"
mkdir "%BIN_DIR%" >nul 2>&1

set "LAUNCHER=%BIN_DIR%\vocabularyplus.cmd"

echo %yellow%Creating launcher...%reset%

(
echo @echo off
echo set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"
echo set "APPDIR=%INSTALL_DIR%"
echo.
echo if "%%1"=="--help" ^(
echo     echo.
echo     echo Usage: vocabularyplus [create] [options]
echo     echo.
echo     echo Commands:
echo     echo   create        Create a new vocabulary file
echo     echo   uninstall     Uninstall Vocabulary Plus
echo     echo.
echo     echo Options:
echo     echo   -v --version  Show version information
echo     echo   --help        Show help
echo     exit /b 0
echo ^)
echo.
echo if "%%1"=="--version" ^(
echo     echo 1.4.0
echo     exit /b 0
echo ^)
echo if "%%1"=="-v" ^(
echo     echo 1.4.0
echo     exit /b 0
echo ^)
echo.
echo if "%%1"=="uninstall" ^(
echo     "%%APPDIR%%\uninstall.cmd"
echo     exit /b 0
echo ^)
echo.
echo if "%%1"=="create" ^(
echo     shift
echo     "%%PY%%" "%%APPDIR%%\create_vocab_file.py" %%%%*
echo ^) else ^(
echo     "%%PY%%" "%%APPDIR%%\main.py" %%%%*
echo ^)
) > "%LAUNCHER%"

echo %green%Launcher created.%reset%

:: Alias
echo @echo off ^& "%LAUNCHER%" %%* > "%BIN_DIR%\vp.cmd"

:: Create uninstaller
set "UNINSTALLER=%INSTALL_DIR%\uninstall.cmd"

(
echo @echo off
echo echo Removing Vocabulary Plus...
echo rmdir /s /q "%INSTALL_DIR%"
echo del "%USERPROFILE%\AppData\Local\Programs\VocabularyPlus\vocabularyplus.cmd" 2^>nul
echo del "%USERPROFILE%\AppData\Local\Programs\VocabularyPlus\vp.cmd" 2^>nul
echo echo Uninstall complete.
) > "%UNINSTALLER%"

echo %green%Uninstaller created.%reset%

:: Start menu shortcut
set "SM_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
set "SHORTCUT=%SM_DIR%\Vocabulary Plus.lnk"

powershell -NoProfile -Command ^
"$s=(New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT%');" ^
"$s.TargetPath='%LAUNCHER%';" ^
"$s.IconLocation='%INSTALL_DIR%\app_icon.png';" ^
"$s.Save()"

echo %green%Start menu shortcut created.%reset%

:: Install Version Manager
echo %yellow%Installing VP Version Manager...%reset%
curl -fsSL "%VP_VM_INSTALLER_URL%" -o install-vm.bat || exit /b 1
call install-vm.bat "%INSTALL_DIR%\vm"
del install-vm.bat

if not exist "%INSTALL_DIR%\vm\versions\vp" mkdir "%INSTALL_DIR%\vm\versions\vp"
echo 1.4.0 > "%INSTALL_DIR%\vm\versions\vp\current.txt"

echo.
echo %green%Vocabulary Plus installed successfully!%reset%
echo.
echo Commands:
echo   vocabularyplus
echo   vocabularyplus create
echo   vp
echo   vp create
echo.
echo If commands do not work, add this to PATH:
echo   %BIN_DIR%
echo.