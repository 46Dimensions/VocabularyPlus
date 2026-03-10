@echo off
setlocal EnableExtensions

:: -----------------------------
:: Silent mode detection
:: -----------------------------

set "SILENT=0"

if /I "%1"=="-s" set SILENT=1
if /I "%1"=="--silent" set SILENT=1

:: -----------------------------
:: ANSI colors
:: -----------------------------

if "%SILENT%"=="0" (
    for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
    set "green=%ESC%[92m"
    set "red=%ESC%[91m"
    set "yellow=%ESC%[93m"
    set "cyan=%ESC%[96m"
    set "reset=%ESC%[0m"
) else (
    set "green="
    set "red="
    set "yellow="
    set "cyan="
    set "reset="
)

call :log "%cyan%=========================================%reset%"
call :log "%cyan%Vocabulary Plus Windows Installer (1.4.1)%reset%"
call :log "%cyan%=========================================%reset%"

:: -----------------------------
:: Install paths
:: -----------------------------

set "INSTALL_DIR=%LOCALAPPDATA%\VocabularyPlus"
set "BIN_DIR=%LOCALAPPDATA%\Programs\VocabularyPlus"

mkdir "%INSTALL_DIR%" >nul 2>&1
mkdir "%BIN_DIR%" >nul 2>&1

:: -----------------------------
:: Python detection
:: -----------------------------

where python >nul 2>&1
if errorlevel 1 (
    call :error "Python 3.10+ is required."
)

for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set "PYVER=%%v"

for /f "tokens=1,2 delims=." %%a in ("%PYVER%") do (
    set "PYMAJOR=%%a"
    set "PYMINOR=%%b"
)

if "%PYMAJOR%" LSS "3" call :error "Python 3.10+ required"
if "%PYMAJOR%"=="3" if "%PYMINOR%" LSS "10" call :error "Python 3.10+ required"

call :log "Python %PYVER% detected"

:: -----------------------------
:: Download files
:: -----------------------------

set "BASE_URL=https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main"

call :log "Downloading files..."

curl -fsSL "%BASE_URL%/main.py" -o "%INSTALL_DIR%\main.py" || call :error "Download failed"
curl -fsSL "%BASE_URL%/create_vocab_file.py" -o "%INSTALL_DIR%\create_vocab_file.py"
curl -fsSL "%BASE_URL%/requirements.txt" -o "%INSTALL_DIR%\requirements.txt"

:: -----------------------------
:: Virtual environment
:: -----------------------------

call :log "Creating virtual environment"

python -m venv "%INSTALL_DIR%\venv" || call :error "venv creation failed"

set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"

"%PY%" -m pip install --upgrade pip >nul
"%PY%" -m pip install -r "%INSTALL_DIR%\requirements.txt"

del "%INSTALL_DIR%\requirements.txt"

:: -----------------------------
:: Launcher creation
:: -----------------------------

set "LAUNCHER=%BIN_DIR%\vocabularyplus.cmd"

call :log "Creating launcher"

(
echo @echo off
echo set "PY=%INSTALL_DIR%\venv\Scripts\python.exe"
echo set "APPDIR=%INSTALL_DIR%"
echo.
echo if "%%1"=="--version" ^(
echo     echo 1.4.0
echo     exit /b
echo ^)
echo.
echo if "%%1"=="create" ^(
echo     shift
echo     "%%PY%%" "%%APPDIR%%\create_vocab_file.py" %%%%*
echo ^) else ^(
echo     "%%PY%%" "%%APPDIR%%\main.py" %%%%*
echo ^)
) > "%LAUNCHER%"

echo @echo off ^& "%LAUNCHER%" %%* > "%BIN_DIR%\vp.cmd"

:: -----------------------------
:: Start menu shortcut
:: -----------------------------

call :log "Creating start menu shortcut"

set "SHORTCUT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk"

powershell -NoProfile -Command "$W=New-Object -ComObject WScript.Shell;$S=$W.CreateShortcut('%SHORTCUT%');$S.TargetPath='%LAUNCHER%';$S.Save()" >nul

:: -----------------------------
:: Uninstaller
:: -----------------------------

call :log "Creating uninstaller"

(
echo @echo off
echo echo Removing Vocabulary Plus...
echo rmdir /s /q "%INSTALL_DIR%"
echo del "%BIN_DIR%\vocabularyplus.cmd" 2^>nul
echo del "%BIN_DIR%\vp.cmd" 2^>nul
echo echo Uninstall complete.
) > "%INSTALL_DIR%\uninstall.cmd"

:: -----------------------------
:: Finished
:: -----------------------------

call :log "%green%Installation complete!%reset%"

if "%SILENT%"=="0" (
    echo.
    echo Commands available:
    echo   vocabularyplus
    echo   vocabularyplus create
    echo   vp
)

exit /b

:: -----------------------------
:: Logging
:: -----------------------------

:log
if "%SILENT%"=="0" echo %~1
exit /b

:error
echo %red%ERROR:%reset% %~1
exit /b 1