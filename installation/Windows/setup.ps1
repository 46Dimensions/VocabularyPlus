# Requires: PowerShell 5+ (Windows 10+)
Set-PSDebug -Trace 2

$ErrorActionPreference = "Stop"

$INSTALL_DIR = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$BIN_DIR = "$env:USERPROFILE\AppData\Local\Programs\VocabularyPlus"
New-Item -ItemType Directory -Path "$BIN_DIR"

# --- Colors ---
function Write-Colour($text, $color) {
    Write-Host $text -ForegroundColor $color
}

function Write-Logo {
    $esc = [char]27
    Write-Host "$esc[38;5;99m🭖█🭀  🭋█🭡   $esc[38;5;171m██████🭏"
    Write-Host "$esc[38;5;105m🭦█🭐  🭅█🭛   $esc[38;5;177m██   🭨█"
    Write-Host "$esc[38;5;141m 🭖█🭀🭋█🭡    $esc[38;5;183m██████🭠"
    Write-Host "$esc[38;5;177m 🭦█🭐🭅█🭛    $esc[38;5;209m██"
    Write-Host "$esc[38;5;209m  🭖██🭡     $esc[38;5;220m██$esc[0m"
    Write-Host "VOCABULARY PLUS"
    Write-Host "Windows Setup (2.0.0)"
    Write-Host ""
}

function Test-Windows {
    # --- Windows version check ---
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        Write-Colour "ERROR: Windows 10 or later is required." Red
        exit 1
    }
}

function Confirm-Install {
    param([string]$Message)

    $response = Read-Host "$Message [Y/N]"
    return $response.Trim().ToLower() -in @('y', 'yes')
}

function Test-Python {
    function Install-Python {
        if (-not (Confirm-Install "Install Python 3.14 now?")) {
            Write-Colour "User declined Python installation. Exiting." Yellow
            exit 1
        }

        Write-Colour "Attempting to install Python 3.14..." Yellow
        Write-Colour "- Running: winget install -e --id Python.Python.3.14 --source winget" Yellow

        try {
            & winget install -e --id Python.Python.3.14 --source winget

            if ($LASTEXITCODE -ne 0) {
                throw "winget exited with code $LASTEXITCODE"
            }

            Write-Colour "- Reloading PATH" Yellow

            $env:PATH = `
                [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + `
                [Environment]::GetEnvironmentVariable("PATH", "User")

            # Actually test that Python works
            $pythonVersion = & python --version 2>&1

            if ($LASTEXITCODE -ne 0 -or $pythonVersion -notmatch "^Python \d+\.\d+\.\d+") {
                throw "Python command is not available after installation."
            }

            Write-Colour "Python installed successfully." Green
        }
        catch {
            Write-Colour "ERROR: Failed to install Python with winget: $_" Red
            exit 1
        }
    }

    # --- Check Python ---
    try {
        $pyver = (& python --version 2>&1)

        if ($LASTEXITCODE -ne 0 -or $pyver -notmatch "^Python \d+\.\d+\.\d+") {
            throw "Python command is not available."
        }

        $pyver = $pyver -replace "^Python ", ""
        $verParts = $pyver.Split(".")

        $major = [int]$verParts[0]
        $minor = [int]$verParts[1]
        Write-Debug "Found Python version $pyver"
    }
    catch {
        Write-Colour "Python not found or not working." Red
        Install-Python
        return
    }

    # --- Check Python version ---
    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
        Write-Colour "ERROR: Python must be >= 3.10 (found $pyver)." Red
        Install-Python
    }
}

Write-Logo

Test-Windows
Test-Python

# --- Check existing install ---
$commandName = "vocabularyplus"
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

# --- Move into install dir ---
Set-Location $INSTALL_DIR

# --- Virtual environment ---
Write-Colour "Creating virtual environment..." Yellow

$VENV_DIR = Join-Path $INSTALL_DIR ".venv"
python -m venv $VENV_DIR

$PY = Join-Path $VENV_DIR "Scripts" "python.exe"

if (-not (Test-Path $PY)) {
    Write-Colour "Python Virtual environment was not created at: $VENV_DIR" Red
    exit 1
}

Write-Colour "Upgrading pip..." Yellow
& $PY -m pip install --upgrade pip

Write-Colour "Installing dependencies..." Yellow
$REQUIREMENTS_FILE = Join-Path $INSTALL_DIR "installation\requirements.txt"
& $PY -m pip install -r $REQUIREMENTS_FILE

# --- Launcher ---
Write-Colour "Setting up launcher..." Yellow

New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
$ORIGINAL_LAUNCHER_LOCATION = Join-Path $INSTALL_DIR "installation" "Windows" "launcher.ps1"
$NEW_LAUNCHER_LOCATION = Join-Path $INSTALL_DIR "vocabularyplus"
$ALIAS_LOCATION = Join-Path $INSTALL_DIR "vp"

$LINK_LOCATION = Join-Path $BIN_DIR "vocabularyplus.ps1"
$ALIAS_LINK_LOCATION = Join-Path $BIN_DIR "vp.ps1"

# Copy from installation directory into $INSTALL_DIR
Copy-Item $ORIGINAL_LAUNCHER_LOCATION $NEW_LAUNCHER_LOCATION
Copy-Item $NEW_LAUNCHER_LOCATION $ALIAS_LOCATION

# Create symlinks in $BIN_DIR
New-Item -ItemType SymbolicLink -Path $LINK_LOCATION -Target $NEW_LAUNCHER_LOCATION
New-Item -ItemType SymbolicLink -Path $ALIAS_LINK_LOCATION -Target $ALIAS_LOCATION

Write-Colour "Launcher set up." Green

# --- Uninstaller ---

Write-Colour "Setting up uninstaller..."
$ORIGINAL_UNINSTALLER_LOCATION = Join-Path $INSTALL_DIR "installation" "Windows" "launcher.ps1"
$NEW_UNINSTALLER_LOCATION = Join-Path $INSTALL_DIR "uninstall"

Copy-Item $ORIGINAL_UNINSTALLER_LOCATION $NEW_UNINSTALLER_LOCATION

Write-Colour "Uninstaller set up" Green

# Set install_dir.txt file
Set-Content -Path (Join-Path $BIN_DIR "install_dir.txt") -Value $INSTALL_DIR

# --- Start Menu shortcut ---
Write-Colour "Creating Start Menu shortcut..." Yellow

$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$LAUNCHER_LOCATION`" menu"
$shortcut.IconLocation = Join-Path "$INSTALL_DIR" "icons" "icon_small.ico"
$shortcut.WorkingDirectory = $INSTALL_DIR
$shortcut.Save()

Write-Colour "Shortcut created." Green

# --- Install VP VM if the user wants to ---
if (Confirm-Install "Install Vocabulary Plus Version Manager?") {
    Write-Colour "Installing Version Manager..." Yellow
    $vmInstaller = Join-Path $env:TEMP "install-vm.ps1"

    # Get latest Version Manager version from GitHub API
    $vmLatestVersion = (Invoke-RestMethod "https://api.github.com/repos/46Dimensions/vp-vm/releases/latest").tag_name

    Invoke-WebRequest "https://raw.githubusercontent.com/46Dimensions/vp-vm/${VmLatestVersion}/install-vm.ps1" -OutFile $vmInstaller
    & $vmInstaller "$INSTALL_DIR"

    Remove-Item $vmInstaller -Force

    # --- Version file ---
    New-Item -ItemType Directory -Force -Path "$INSTALL_DIR\vm\versions\vp" | Out-Null
    "1.5.1" | Set-Content "$INSTALL_DIR\vm\versions\vp\current.txt"

    Write-Colour "Version Manager installed." Greens
}

# --- About file ---
$DATE = (Get-Date -Format g)
@"
Vocabulary Plus
Copyright (c) 2025 46Dimensions

Version: 1.5.1
Installed on: $DATE
Platform: Windows
Developer: 46Dimensions

Website: https://github.com/46Dimensions/VocabularyPlus
License: Mit License. See $INSTALL_DIR\LICENSE for details.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@ | Set-Content "$INSTALL_DIR\about.txt"
Write-Colour "Created final files." Green

# Remove installation directory
Remove-Item -Recurse -Force "$INSTALL_DIR\installation"

# --- Paths ---
Add-ToUserPath $BIN_DIR

# --- Done ---
Write-Host ""
Write-Colour "Vocabulary Plus 1.5.1 installed successfully!" Green
Write-Host ""
Write-Host "To open Vocabulary Plus, run:"
Write-Host "  vocabularyplus"
Write-Host "  vp"
Write-Host "or use the desktop app."
Write-Host ""
Write-Host "If commands don't work, open a new terminal or add this to PATH:"
Write-Host "  $BIN_DIR"

Set-PSDebug -Off