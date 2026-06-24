# Requires: PowerShell 5+ (Windows 10+)

$ErrorActionPreference = "Stop"

$BASE_URL = "https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/1.5.0"
$INSTALL_DIR = Join-Path $PWD "VocabularyPlus"
$BIN_DIR = "$env:USERPROFILE\AppData\Local\Programs\VocabularyPlus"

# --- Download Functions ---
function Download($url, $out) {
    Write-Colour "- Downloading $out..." Yellow
    Invoke-WebRequest $url -OutFile $out
}

function DownloadSilent($url, $out) {
    Invoke-WebRequest $url -OutFile $out
}

# --- Colors ---
function Write-Colour($text, $color) {
    Write-Host $text -ForegroundColor $color
}

function Write-BasicLogo {
    Write-Colour "==========================================" Cyan
    Write-Colour "Vocabulary Plus: Windows Installer (1.5.0)" Cyan
    Write-Colour "==========================================" Cyan
}

function Write-ComplexLogo {
    DownloadSilent "$BASE_URL/icons/text_icon.txt" "$INSTALL_DIR\text_icon.txt"
    Get-Content "$INSTALL_DIR\text_icon.txt"
}

function WindowsVersionCheck {
    # --- Windows version check ---
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        Write-Colour "ERROR: Windows 10 or later is required." Red
        exit 1
    }
}

function PSVersionCheck {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        return 1
    }
    else {
        return 0
    }
}

function Confirm-Install {
    param([string]$Message)

    $response = Read-Host "$Message [Y/N]"
    return $response.Trim().ToLower() -in @('y', 'yes')
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

# Only PowerShell 7 supports ANSI codes for the complex logo, so check the PS version and display the appropriate logo.
if (PSVersionCheck -eq 0) {
    Write-BasicLogo
    Write-Colour "PowerShell 7 or later is required for complex logo." Yellow
    Write-Host ""
}
else {
    Write-ComplexLogo
}

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
Add-ToUserPath $BIN_DIR

# --- Create install dir ---
Write-Colour "Creating VocabularyPlus directory..." Yellow
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
Set-Location $INSTALL_DIR

# --- Download files ---
Download "$BASE_URL/requirements.txt" "requirements.txt"
Download "$BASE_URL/main.py" "main.py"
Download "$BASE_URL/create_vocab_file.py" "create_vocab_file.py"
Download "$BASE_URL/menu.py" "menu.py"
Download "$BASE_URL/icons/icon_small.ico" "app_icon.ico"
Download "$BASE_URL/LICENSE" "LICENSE"

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
$LAUNCHER_LOCATION = Join-Path $BIN_DIR "vocabularyplus.ps1"
$ALIAS_LOCATION = Join-Path $BIN_DIR "vp.ps1"

Set-Content -Path (Join-Path $BIN_DIR "install_dir.txt") -Value $INSTALL_DIR

Write-Colour "Downloading launcher..." Yellow

Download $BASE_URL/launcher.ps1 $LAUNCHER_LOCATION
Copy-Item $LAUNCHER_LOCATION $ALIAS_LOCATION

Write-Colour "Launcher downloaded." Green

# --- Uninstaller ---
$UNINSTALLER_PATH = Join-Path $INSTALL_DIR "uninstall.ps1"

Write-Colour "Downloading uninstaller..." Yellow

Download $BASE_URL/uninstall.ps1 $UNINSTALLER_PATH

Write-Colour "Uninstaller downloaded." Green

# --- Start Menu shortcut ---
Write-Colour "Creating Start Menu shortcut..." Yellow

$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$LAUNCHER_LOCATION`" menu"
$shortcut.IconLocation = Join-Path $INSTALL_DIR 'app_icon.ico'
$shortcut.WorkingDirectory = $INSTALL_DIR
$shortcut.Save()

Write-Colour "Shortcut created." Green

# --- Install VP VM ---
Write-Colour "Installing Version Manager..." Yellow
$vmInstaller = Join-Path $env:TEMP "install-vm.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/46Dimensions/vp-vm/1.1.0/install-vm.ps1" -OutFile $vmInstaller
& $vmInstaller "$INSTALL_DIR"

Remove-Item $vmInstaller -Force

Write-Colour "Version Manager installed." Green

Write-Colour "Creating final files..." Yellow
# --- Version file ---
New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\vm\versions\vp" | Out-Null
"1.5.0" | Set-Content "$INSTALL_DIR\vm\versions\vp\current.txt"

# --- Bin directory file ---
Set-Content -Path (Join-Path $INSTALL_DIR ".bin_dir.txt") -Value $BIN_DIR

# --- About file ---
$DATE = (Get-Date)
@"
Vocabulary Plus
Version: 1.5.0
Installed on: $DATE
Platform: Windows
Developer: 46Dimensions

Website: https://github.com/46Dimensions/VocabularyPlus
License: Mit License. See $INSTALL_DIR\LICENSE for details.
"@ | Set-Content "$INSTALL_DIR\about.txt"
Write-Colour "Created final files." Green

# --- Done ---
Write-Host ""
Write-Colour "Vocabulary Plus 1.5.0 installed successfully!" Green
Write-Host ""
Write-Host "Commands:"
Write-Host "  vocabularyplus"
Write-Host "  vocabularyplus create"
Write-Host "  vp"
Write-Host "  vp create"
Write-Host ""
Write-Host "If commands don't work, add to PATH:"
Write-Host "  $BIN_DIR"

Set-Location $INSTALL_DIR\..