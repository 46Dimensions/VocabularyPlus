# Requires: PowerShell 5+ (Windows 10+)

$ErrorActionPreference = "Stop"

function Confirm-Install {
    param([string]$Message)

    $response = Read-Host "$Message [Y/N]"
    return $response.Trim().ToLower() -in @('y', 'yes')
}

# --- Colors ---
function Write-Colour($text, $color) {
    Write-Host $text -ForegroundColor $color
}

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
$LAUNCHER_SCRIPT = Join-Path $BIN_DIR "vocabularyplus.ps1"
$LAUNCHER_CMD = Join-Path $BIN_DIR "vocabularyplus.cmd"
$ALIAS_SCRIPT = Join-Path $BIN_DIR "vp.ps1"
$ALIAS_CMD = Join-Path $BIN_DIR "vp.cmd"

Write-Colour "Creating PowerShell launcher script..." Yellow

@"
param()

function Show-Help {
    Write-Host ""
    Write-Host "Usage: vocabularyplus [create] [options]"
    Write-Host "Commands:"
    Write-Host "  create        Create a new vocabulary file"
    Write-Host "  uninstall     Uninstall Vocabulary Plus"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -v, --version   Show version information"
    Write-Host "  --help          Show this help message"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Python = Join-Path $ScriptDir "venv\Scripts\python.exe"
$UninstallScript = Join-Path $ScriptDir "uninstall.ps1"
$RemainingArgs = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

if ($args.Count -gt 0) {
    switch ($args[0].ToLower()) {
        '--help' { Show-Help; exit 0 }
        '-h' { Show-Help; exit 0 }
        '--version' { Write-Host "1.4.0"; exit 0 }
        '-v' { Write-Host "1.4.0"; exit 0 }
        'uninstall' {
            & $UninstallScript @RemainingArgs
            exit $LASTEXITCODE
        }
        'create' {
            & $Python (Join-Path $ScriptDir "create_vocab_file.py") @RemainingArgs
            exit $LASTEXITCODE
        }
        Default {
            & $Python (Join-Path $ScriptDir "main.py") @args
            exit $LASTEXITCODE
        }
    }
} else {
    & $Python (Join-Path $ScriptDir "main.py")
    exit $LASTEXITCODE
}
"@ | Set-Content -Encoding UTF8 $LAUNCHER_SCRIPT

Write-Colour "Creating launcher shim..." Yellow

@"
@echo off
set "SCRIPT=%~dp0\vocabularyplus.ps1"
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
"@ | Set-Content -Encoding ASCII $LAUNCHER_CMD

Write-Colour "Creating alias script..." Yellow

@"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir 'vocabularyplus.ps1') @args
"@ | Set-Content -Encoding UTF8 $ALIAS_SCRIPT

Write-Colour "Creating alias..." Yellow

@"
@echo off
set "SCRIPT=%~dp0\vp.ps1"
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
"@ | Set-Content -Encoding ASCII $ALIAS_CMD

Write-Colour "Launcher created." Green

# --- Uninstaller ---
$UNINSTALLER = Join-Path $INSTALL_DIR "uninstall.ps1"

Write-Colour "Creating PowerShell uninstaller..." Yellow

@"
param(
    [switch]$Silent
)

function Write-Log {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

$InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir = Join-Path $env:USERPROFILE 'AppData\Local\Programs\VocabularyPlus'
$ShortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk'
$ScriptPath = $MyInvocation.MyCommand.Path

Write-Log '==========================================' Cyan
Write-Log 'Vocabulary Plus: Uninstaller (1.4.0)' Cyan
Write-Log '==========================================' Cyan
Write-Log ''

Write-Log 'Removing virtual environment...' Yellow
Remove-Item -LiteralPath (Join-Path $InstallDir 'venv') -Recurse -Force -ErrorAction SilentlyContinue

Write-Log 'Removing application files...' Yellow
Remove-Item -LiteralPath (Join-Path $InstallDir 'main.py') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $InstallDir 'create_vocab_file.py') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $InstallDir 'app_icon.png') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $InstallDir 'requirements.txt') -Force -ErrorAction SilentlyContinue

Write-Log 'Removing VM files...' Yellow
Remove-Item -LiteralPath (Join-Path $InstallDir 'vm') -Recurse -Force -ErrorAction SilentlyContinue

Write-Log 'Removing launchers...' Yellow
Remove-Item -LiteralPath (Join-Path $BinDir 'vocabularyplus.cmd') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $BinDir 'vp.cmd') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $BinDir 'vocabularyplus.ps1') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $BinDir 'vp.ps1') -Force -ErrorAction SilentlyContinue

Write-Log 'Removing Start Menu shortcut...' Yellow
if (Test-Path -LiteralPath $ShortcutPath) {
    Remove-Item -LiteralPath $ShortcutPath -Force -ErrorAction SilentlyContinue
}

Write-Log 'Removing remaining installation files...' Yellow
Get-ChildItem -LiteralPath $InstallDir -Force | Where-Object { $_.FullName -ne $ScriptPath } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Log 'Done.' Green
"@ | Set-Content -Encoding UTF8 $UNINSTALLER

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