# Requires: PowerShell 5+ (Windows 10+)

$ErrorActionPreference = "Stop"

# --- Colors ---
function Write-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Color "==========================================" Cyan
Write-Color "Vocabulary Plus: Windows Installer (1.4.0)" Cyan
Write-Color "==========================================" Cyan
Write-Host ""

# --- Windows version check ---
if ([Environment]::OSVersion.Version.Major -lt 10) {
    Write-Color "ERROR: Windows 10 or later is required." Red
    exit 1
}

# --- Python check ---
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Color "ERROR: Python not found. Install Python 3.10+." Red
    exit 1
}

$pyver = (& python --version) -replace "Python ", ""
$verParts = $pyver.Split(".")
$major = [int]$verParts[0]
$minor = [int]$verParts[1]

if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
    Write-Color "ERROR: Python must be >= 3.10 (found $pyver)" Red
    exit 1
}

# --- Check existing install ---
$commandName = "vocabularyplus.cmd"
if (Get-Command $commandName -ErrorAction SilentlyContinue) {
    Write-Color "ERROR: Vocabulary Plus appears to already be installed." Red
    exit 1
}

function Add-ToUserPath {
    param([string]$NewPath)

    $current = [Environment]::GetEnvironmentVariable("PATH", "User")

    if (-not $current) { $current = "" }

    $paths = $current -split ";" | Where-Object { $_ -ne "" }

    if ($paths -contains $NewPath) {
        Write-Host "PATH already contains: $NewPath" -ForegroundColor DarkGray
        return
    }

    $newPathValue = ($paths + $NewPath) -join ";"

    [Environment]::SetEnvironmentVariable("PATH", $newPathValue, "User")

    # Also update current session immediately
    $env:PATH = $newPathValue

    Write-Host "Added to PATH: $NewPath" -ForegroundColor Green
}

# --- Paths ---
$BASE_URL = "https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main"
$INSTALL_DIR = Join-Path $PWD "VocabularyPlus"
$BIN_DIR = "$env:USERPROFILE\AppData\Local\Programs\VocabularyPlus"
Add-ToUserPath $BIN_DIR

# --- Create install dir ---
Write-Color "Creating VocabularyPlus directory..." Yellow
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
Set-Location $INSTALL_DIR

# --- Download files ---
function Download($url, $out) {
    Write-Color "Downloading $out..." Yellow
    Invoke-WebRequest $url -OutFile $out
}

Download "$BASE_URL/requirements.txt" "requirements.txt"
Download "$BASE_URL/main.py" "main.py"
Download "$BASE_URL/create_vocab_file.py" "create_vocab_file.py"
Download "$BASE_URL/app_icon.png" "app_icon.png"

# --- Virtual environment ---
Write-Color "Creating virtual environment..." Yellow
python -m venv venv

$PY = Join-Path $INSTALL_DIR "venv\Scripts\python.exe"

Write-Color "Upgrading pip..." Yellow
& $PY -m pip install --upgrade pip

Write-Color "Installing dependencies..." Yellow
& $PY -m pip install -r requirements.txt

Remove-Item requirements.txt -Force

# --- Launcher ---
New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
$LAUNCHER = Join-Path $BIN_DIR "vocabularyplus.cmd"

Write-Color "Creating launcher..." Yellow

@"
@echo off
set "PY=$INSTALL_DIR\venv\Scripts\python.exe"
set "APPDIR=$INSTALL_DIR"

if "%1"=="--help" (
    echo.
    echo Usage: vocabularyplus [create] [options]
    echo Commands:
    echo   create        Create a new vocabulary file
    echo   uninstall     Uninstall Vocabulary Plus
    echo Options:
    echo   -v, --version   Show version information
    echo   --help          Show this help message
    exit /b 0
)

if "%1"=="--version" (
    echo 1.4.0
    exit /b 0
)

if "%1"=="-v" (
    echo 1.4.0
    exit /b 0
)

if "%1"=="uninstall" (
    "%APPDIR%\uninstall.cmd"
    exit /b 0
)

if "%1"=="create" (
    shift
    "%PY%" "%APPDIR%\create_vocab_file.py" %*
) else (
    "%PY%" "%APPDIR%\main.py" %*
)
"@ | Set-Content -Encoding ASCII $LAUNCHER

Write-Color "Launcher created." Green

# --- Alias ---
$aliasPath = Join-Path $BIN_DIR "vp.cmd"
"@echo off`n`"$LAUNCHER`" %*" | Set-Content -Encoding ASCII $aliasPath

# --- Uninstaller ---
$UNINSTALLER = Join-Path $INSTALL_DIR "uninstall.cmd"

Write-Color "Creating uninstaller..." Yellow

@"
@echo off
echo =========================================
echo Vocabulary Plus: Uninstaller (1.4.0)
echo =========================================
echo.

echo Removing files...
rmdir /s /q "$INSTALL_DIR\venv"
del /q "$INSTALL_DIR\main.py"
del /q "$INSTALL_DIR\create_vocab_file.py"
del /q "$INSTALL_DIR\app_icon.png"

echo Removing launchers...
del /q "$BIN_DIR\vocabularyplus.cmd"
del /q "$BIN_DIR\vp.cmd"

echo Done.
"@ | Set-Content -Encoding ASCII $UNINSTALLER

Write-Color "Uninstaller created." Green

# --- Start Menu shortcut ---
Write-Color "Creating Start Menu shortcut..." Yellow

$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $LAUNCHER
$shortcut.IconLocation = "$INSTALL_DIR\app_icon.png"
$shortcut.Save()

Write-Color "Shortcut created." Green

# --- Install VP VM ---
Write-Color "Installing Version Manager..." Yellow

$vmInstaller = "install-vm.bat"
Invoke-WebRequest "https://raw.githubusercontent.com/46Dimensions/vp-vm/main/install-vm.bat" -OutFile $vmInstaller

cmd /c "$vmInstaller `"$INSTALL_DIR\vm`""

Remove-Item $vmInstaller -Force

# --- Version file ---
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\vm\versions\vp" | Out-Null
"1.4.0" | Set-Content "$INSTALL_DIR\vm\versions\vp\current.txt"

# --- Done ---
Write-Host ""
Write-Color "Vocabulary Plus 1.4.0 installed successfully!" Green
Write-Host ""
Write-Host "Commands:"
Write-Host "  vocabularyplus"
Write-Host "  vocabularyplus create"
Write-Host "  vp"
Write-Host "  vp create"
Write-Host ""
Write-Host "If commands don't work, add to PATH:"
Write-Host "  $BIN_DIR"