# Requires: PowerShell 5+ (Windows 10+)

$ErrorActionPreference = "Stop"

function Install-PowerShell7 {
    Write-Colour "Checking PowerShell 7..." Yellow
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwsh) {
        Write-Colour "PowerShell 7 not found. Installing..." Yellow
        try {
            & winget install --id Microsoft.Powershell --source winget
        }
        catch {
            Write-Colour "ERROR: Failed to install PowerShell 7 with winget: $_" Red
            exit 1
        }
        $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
        if (-not $pwsh) {
            Write-Colour "ERROR: PowerShell 7 installation completed but pwsh.exe was not found." Red
            exit 1
        }
    }
    $version = (& pwsh -NoProfile -Command '$PSVersionTable.PSVersion.Major') -as [int]
    if ($version -lt 7) {
        Write-Colour "ERROR: Installed PowerShell version is $version, but PowerShell 7 is required." Red
        exit 1
    }
}

function Confirm-Install {
    param([string]$Message)

    $response = Read-Host "$Message [Y/N]"
    return $response.Trim().ToLower() -in @('y', 'yes')
}

function Test-PowerShell7 {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Colour "PowerShell 7 is required for this installer." Yellow
        if (-not (Confirm-Install "Install PowerShell 7 now?")) {
            Write-Colour "User declined PowerShell 7 installation. Exiting." Yellow
            exit 1
        }

        Install-PowerShell7
        Write-Colour "Restarting script in PowerShell 7..." Yellow
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path @args
        exit $LASTEXITCODE
    }
}

# --- Colors ---
function Write-Colour($text, $color) {
    Write-Host $text -ForegroundColor $color
}

# --- PowerShell 7 ---
Test-PowerShell7

Write-Colour "==========================================" Cyan
Write-Colour "Vocabulary Plus: Windows Installer (1.4.0)" Cyan
Write-Colour "==========================================" Cyan
Write-Host ""

function WindowsVersionCheck {
    # --- Windows version check ---
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        Write-Colour "ERROR: Windows 10 or later is required." Red
        exit 1
    }
}

function PythonCheck {
    function Install-Python {
        if (-not (Confirm-Install "Install Python 3.14 now?")) {
            Write-Colour "User declined PowerShell 7 installation. Exiting." Yellow
            exit 1
        }
        Write-Colour "Attempting to install Python 3.14..." Yellow
        Write-Colour "- Running: winget install -e --id Python.Python.3.14 --source winget" Yellow
        
        try {
            & winget install -e --id Python.Python.3.14 --source winget

            Write-Colour "- Reloading PATH" Yellow
            # Reload PATH to make newly installed Python available
            $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
            $python = Get-Command python -ErrorAction SilentlyContinue
            
            if (-not $python) {
                Write-Colour "ERROR: Python installation failed or Python command not available after install." Red
                exit 1
            }
            Write-Colour "Python installed successfully." Green
        }
        catch {
            Write-Colour "ERROR: Failed to install Python with winget: $_" Red
            exit 1
        }
    }

    # --- Python check ---
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        Write-Colour "Python not found." Red
        Install-Python
    }

    # --- Check Python version ---
    try {
        $pyver = (& python --version) -replace "Python ", ""
        $verParts = $pyver.Split(".")
        $major = [int]$verParts[0]
        $minor = [int]$verParts[1]
    }
    catch {
        Write-Colour "ERROR: Could not determine Python version." Red
        Install-Python
    }

    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
        Write-Colour "ERROR: Python must be >= 3.10 (found $pyver)." Red
        Install-Python
    }
}

WindowsVersionCheck
PythonCheck

# --- Check existing install ---
$commandName = "vocabularyplus.cmd"
if (Get-Command $commandName -ErrorAction SilentlyContinue) {
    Write-Colour "ERROR: Vocabulary Plus appears to already be installed." Red
    exit 1
}

function Add-ToUserPath {
    param([string]$NewPath)

    Write-Colour "Setting up PATH" Yellow

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
Write-Colour "Creating VocabularyPlus directory..." Yellow
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
Set-Location $INSTALL_DIR

# --- Download files ---
function Download($url, $out) {
    Write-Colour "- Downloading $out..." Yellow
    Invoke-WebRequest $url -OutFile $out
}

Download "$BASE_URL/requirements.txt" "requirements.txt"
Download "$BASE_URL/main.py" "main.py"
Download "$BASE_URL/create_vocab_file.py" "create_vocab_file.py"
Download "$BASE_URL/app_icon.png" "app_icon.png"

# --- Virtual environment ---
Write-Colour "Creating virtual environment..." Yellow
python -m venv venv

$PY = Join-Path $INSTALL_DIR "venv\Scripts\python.exe"

Write-Colour "Upgrading pip..." Yellow
& $PY -m pip install --upgrade pip

Write-Colour "Installing dependencies..." Yellow
& $PY -m pip install -r requirements.txt

Remove-Item requirements.txt -Force

# --- Launcher ---
New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
$LAUNCHER = Join-Path $BIN_DIR "vocabularyplus.cmd"

Write-Colour "Creating launcher..." Yellow

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

Write-Colour "Launcher created." Green

# --- Alias ---
$aliasPath = Join-Path $BIN_DIR "vp.cmd"
"@echo off`n`"$LAUNCHER`" %*" | Set-Content -Encoding ASCII $aliasPath

# --- Uninstaller ---
$UNINSTALLER = Join-Path $INSTALL_DIR "uninstall.cmd"

Write-Colour "Creating uninstaller..." Yellow

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

Write-Colour "Uninstaller created." Green

# --- Start Menu shortcut ---
Write-Colour "Creating Start Menu shortcut..." Yellow

$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $LAUNCHER
$shortcut.IconLocation = "$INSTALL_DIR\app_icon.png"
$shortcut.Save()

Write-Colour "Shortcut created." Green

# --- Install VP VM ---
Write-Colour "Installing Version Manager..." Yellow

$vmInstaller = Join-Path $env:TEMP "install-vm.ps1"

Invoke-WebRequest "https://raw.githubusercontent.com/46Dimensions/vp-vm/1.1.0/install-vm.ps1" -OutFile $vmInstaller

& $vmInstaller "$INSTALL_DIR"

Remove-Item $vmInstaller -Force

# --- Version file ---
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\vm\versions\vp" | Out-Null
"1.4.0" | Set-Content "$INSTALL_DIR\vm\versions\vp\current.txt"

# --- Done ---
Write-Host ""
Write-Colour "Vocabulary Plus 1.4.0 installed successfully!" Green
Write-Host ""
Write-Host "Commands:"
Write-Host "  vocabularyplus"
Write-Host "  vocabularyplus create"
Write-Host "  vp"
Write-Host "  vp create"
Write-Host ""
Write-Host "If commands don't work, add to PATH:"
Write-Host "  $BIN_DIR"