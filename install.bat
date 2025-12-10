@echo off
setlocal ENABLEDELAYEDEXPANSION

:: ANSI escape sequences for colours
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "red=%ESC%[31m"
set "green=%ESC%[32m"
set "yellow=%ESC%[33m"
set "reset=%ESC%[0m"

echo %green%=======================================%reset%
echo %green%Vocabulary Plus Windows Installer 1.0.3%reset%
echo %green%=======================================%reset%
echo.

:: URLs
set "BASE_URL=https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main"
set "REQ_URL=%BASE_URL%/requirements.txt"
set "MAIN_URL=%BASE_URL%/main.py"
set "CREATE_URL=%BASE_URL%/create_vocab_file.py"
set "ICON_URL=%BASE_URL%/app_icon.png"

:: Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo %red%ERROR: Python not found. Please install Python 3.10+.%reset%
    exit /b 1
)

:: Check Python version
for /f "tokens=2 delims= " %%v in ('python --version') do set "PYVER=%%v"
for /f "tokens=1-3 delims=." %%a in ("%PYVER%") do (
    set MAJOR=%%a
    set MINOR=%%b
)
if %MAJOR% LSS 3 (
    echo %red%ERROR: Python version too old.%reset%
    exit /b 1
)
if %MAJOR%==3 if %MINOR% LSS 10 (
    echo %red%ERROR: Python must be 3.10 or higher.%reset%
    exit /b 1
)

:: Install directories
set "INSTALL_DIR=%USERPROFILE%\VocabularyPlus"
set "LAUNCHER_DIR=%USERPROFILE%\AppData\Local\Programs\VocabularyPlus"
mkdir "%INSTALL_DIR%" 2>nul
mkdir "%LAUNCHER_DIR%" 2>nul

:: Download files
echo %yellow%Downloading files...%reset%
curl -fsSL "%REQ_URL%" -o "%INSTALL_DIR%\requirements.txt" 2>nul || powershell -NoLogo -Command "Invoke-WebRequest '%REQ_URL%' -OutFile '%INSTALL_DIR%\requirements.txt'"
curl -fsSL "%MAIN_URL%" -o "%INSTALL_DIR%\main.py" 2>nul || powershell -NoLogo -Command "Invoke-WebRequest '%MAIN_URL%' -OutFile '%INSTALL_DIR%\main.py'"
curl -fsSL "%CREATE_URL%" -o "%INSTALL_DIR%\create_vocab_file.py" 2>nul || powershell -NoLogo -Command "Invoke-WebRequest '%CREATE_URL%' -OutFile '%INSTALL_DIR%\create_vocab_file.py'"
curl -fsSL "%ICON_URL%" -o "%INSTALL_DIR%\app_icon.png" 2>nul || powershell -NoLogo -Command "Invoke-WebRequest '%ICON_URL%' -OutFile '%INSTALL_DIR%\app_icon.png'"

:: Create virtual environment
echo %yellow%Creating virtual environment...%reset%
python -m venv "%INSTALL_DIR%\venv"

set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"
if not exist "%PY%" (
    echo %red%ERROR: Could not find Python in venv.%reset%
    exit /b 1
)

echo %yellow%Upgrading pip...%reset%
"%PY%" -m pip install --upgrade pip

echo %yellow%Installing dependencies...%reset%
"%PY%" -m pip install -r "%INSTALL_DIR%\requirements.txt"
del "%INSTALL_DIR%\requirements.txt"

:: Create main launcher batch file
set "LAUNCHER=%LAUNCHER_DIR%\vocabularyplus.bat"
echo %yellow%Creating launcher at %LAUNCHER%...%reset%
(
echo @echo off
echo set "INSTALL_DIR=%INSTALL_DIR%"
echo set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"
echo if "%%1"=="create" (
echo     shift
echo     "%%PY%%" "%%INSTALL_DIR%%\create_vocab_file.py" %%*
echo ) else (
echo     "%%PY%%" "%%INSTALL_DIR%%\main.py" %%*
echo )
) > "%LAUNCHER%"

:: Create alias batch file "vp.bat"
set "ALIAS=%LAUNCHER_DIR%\vp.bat"
echo %yellow%Creating alias launcher at %ALIAS%...%reset%
(
echo @echo off
echo call "%LAUNCHER%" %%*
) > "%ALIAS%"

:: Add launcher directory to PATH for current session
set "PATH=%LAUNCHER_DIR%;%PATH%"

echo %yellow%Creating Windows shortcuts...%reset%

:: Uses PowerShell to create .lnk files with icons
set "SHORTCUT_TARGET=%LAUNCHER%"
set "SHORTCUT_ICON=%INSTALL_DIR%\app_icon.png"

:: Start Menu folder
set "STARTMENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Vocabulary Plus"

mkdir "%STARTMENU%" 2>nul

:: Create Start Menu shortcut
powershell -command ^
   "$s=(New-Object -COM WScript.Shell).CreateShortcut('%STARTMENU%\Vocabulary Plus.lnk');" ^
   "$s.TargetPath='%SHORTCUT_TARGET%';" ^
   "$s.IconLocation='%SHORTCUT_ICON%';" ^
   "$s.Save()"

:: Create Desktop shortcut
powershell -command ^
   "$s=(New-Object -COM WScript.Shell).CreateShortcut('$env:USERPROFILE\Desktop\Vocabulary Plus.lnk');" ^
   "$s.TargetPath='%SHORTCUT_TARGET%';" ^
   "$s.IconLocation='%SHORTCUT_ICON%';" ^
   "$s.Save()"

echo.
echo %green%Vocabulary Plus 1.0.3 installed successfully%reset%
echo You can now run:
echo   vocabularyplus
echo   vocabularyplus create
echo   vp
echo   vp create
echo.
echo Start Menu and Desktop shortcuts have been created.
echo No PATH changes are strictly required anymore.
echo.
echo %yellow%If you want to uninstall, just delete:%reset%
echo   %INSTALL_DIR%
echo   %LAUNCHER_DIR%
echo   The Start Menu and Desktop shortcuts