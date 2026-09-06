#!/usr/bin/env sh
set -e

# -------------------
# Version information
# -------------------
VERSION="v2.0.0-beta3"
VERSION_DISPLAY="2.0.0 Beta 3"
DEVELOPMENT_BRANCH="2.0.0"

# Don't do anything with version or development branch
: "$VERSION $DEVELOPMENT_BRANCH"

# ------------------
# Helper definitions
# ------------------

# ANSI colours
red="\033[91m"
green="\033[92m"
yellow="\033[93m"
cyan="\033[36m"
reset="\033[0m"

progress=$cyan
success=$green
warning=$yellow
error=$red

# Function to get the directory of this script
get_script_dir() {
    script_dir=$(dirname -- "$0")
    case $script_dir in
        /*) printf '%s\n' "$script_dir" ;;
        *) printf '%s\n' "$PWD/$script_dir" ;;
    esac
}

# Coloured text helpers
write_progress() {
    text=$1
    echo "${progress}${text}${reset}"
}

write_success() {
    text=$1
    echo "${success}${text}${reset}"
}

write_warning() {
    text=$1
    echo "${warning}${text}${reset}"
}

write_error() {
    text=$1
    echo "${error}${text}${reset}"
}

confirm() {
    message=$1

    if [ "$CI" = "true" ]; then
        return 0
    fi

    while true; do
        printf "%s [Y/N] " "$message"
        read -r answer

        case "$answer" in
            [Yy])
                return 0
                ;;
            [Nn])
                return 1
                ;;
            *)
                printf "Please answer Y or N.\n"
                ;;
        esac
    done
}

# Disable stdout if $1 is -s or --silent
SILENT=0
case "$1" in
  -s|--silent) SILENT=1 ;;
esac

if [ "$SILENT" -eq 1 ]; then
  exec >/dev/null
fi


# ----
# Icon
# ----
echo "[38;5;99m🭖█🭀  🭋█🭡   [38;5;171m██████🭏"
echo "[38;5;105m🭦█🭐  🭅█🭛   [38;5;177m██   🭨█"
echo "[38;5;141m 🭖█🭀🭋█🭡    [38;5;183m██████🭠"
echo "[38;5;177m 🭦█🭐🭅█🭛    [38;5;209m██"
echo "[38;5;209m  🭖██🭡     [38;5;220m██[0m"
echo "VOCABULARY PLUS"
echo "Mac Setup ($VERSION_DISPLAY)"


# -------------
# System checks
# -------------

check_system() {
    if [ "$(uname)" != "Darwin" ]; then
        write_error "Not running on MacOS. Use VocabularyPlus/installation/Linux/setup.sh instead."
    fi
}

check_python() {
    command -v python3 >/dev/null 2>&1 || {
        write_error "Python 3 not found. Vocabulary Plus requires Python 3.10+."
        exit 1
    }

    PYVER=$(python3 --version 2>&1 | awk '{print $2}')
    MAJOR=$(printf "%s" "$PYVER" | cut -d. -f1)
    MINOR=$(printf "%s" "$PYVER" | cut -d. -f2)

    echo "Found Python version $PYVER"

    if [ "$MAJOR" -lt 3 ] || { [ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 10 ]; }; then
        write_error "Python must be 3.10 or later (found $PYVER)."
        exit 1
    fi
}

install_python() {
    write_progress "Installing Python..."

    # Check if Homebrew is installed
    if command -v brew >/dev/null 2>&1; then
        brew install python
    else
        # Print an error if Homebrew is not found.
        write_error "Error: Homebrew is not installed."
        exit 1
    fi
}

check_for_installation() {
    if [ -f "$HOME/.local/bin/vocabularyplus" ]; then
        write_error "ERROR: Vocabulary Plus appears to be already installed."
        exit 1
    fi
}

check_system

if ! check_python; then
    if confirm "Install Python now?"; then
        install_python

        # Check Python again
        if ! check_python; then
            write_error "Cannot automatically install Python. Please download and install Python from https://python.org/downloads ."
        fi

    else
        write_error "Exiting..."
        exit 1
    fi
fi


# ------------------
# Define directories
# ------------------

file_dir=$(get_script_dir)
INSTALL_DIR="$(dirname "$(dirname "$(dirname "$file_dir")")")"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

echo "Installation directory: $INSTALL_DIR"
echo "Bin directory: $BIN_DIR"

add_to_path "$BIN_DIR"
cd "$INSTALL_DIR"


# -------------------------
# Virtual Environment setup
# -------------------------
write_progress "Creating virtual environment..."
python3 -m venv .venv || { write_error "Failed to create venv"; exit 1; }

PY="$INSTALL_DIR/.venv/bin/python3"

write_progress "Upgrading pip..."
"$PY" -m pip install --upgrade pip

write_progress "Installing dependencies..."
"$PY" -m pip install -r "$INSTALL_DIR/installation/requirements.txt"


# ------------
# Script setup
# ------------

# Function to add "$INSTALL_DIR" to the 3rd line of a script,
# if it contains "set -e" on second line, after a shebang
write_script_with_install_dir() {
  contents=$1
  out=$2

  printf '%s\n' "$contents" | awk -v install_dir="$INSTALL_DIR" '
    NR == 1 { print; next }
    NR == 2 && $0 ~ /^set -e/ {
      print
      print ""
      print "INSTALL_DIR=\"" install_dir "\""
      print ""
      next
    }
    { print }
  ' > "$out"

  chmod +x "$out"
}

write_progress "Setting up launcher..."
# Copy launcher to VocabularyPlus/vocabularyplus
CURRENT_LAUNCHER_PATH="$INSTALL_DIR/installation/Linux/launcher.sh"
NEW_LAUNCHER_PATH="$INSTALL_DIR/vocabularyplus"
cp "$CURRENT_LAUNCHER_PATH" "$NEW_LAUNCHER_PATH"

LAUNCHER_PATH=$NEW_LAUNCHER_PATH
LAUNCHER_CONTENTS=$(cat "$LAUNCHER_PATH")

# Add install dir to launcher
write_script_with_install_dir "$LAUNCHER_CONTENTS" "$LAUNCHER_PATH"

write_progress "Setting up uninstaller..."
# Copy launcher to VocabularyPlus/uninstall
CURRENT_UNINSTALLER_PATH="$INSTALL_DIR/installation/Linux/uninstall.sh"
NEW_UNINSTALLER_PATH="$INSTALL_DIR/uninstall"
cp "$CURRENT_UNINSTALLER_PATH" "$NEW_UNINSTALLER_PATH"

UNINSTALLER_PATH=$NEW_UNINSTALLER_PATH
UNINSTALLER_CONTENTS=$(cat "$UNINSTALLER_PATH")

# Add install dir to uninstaller
write_script_with_install_dir "$UNINSTALLER_CONTENTS" "$UNINSTALLER_PATH"


# Set about file
DATE=$(date "+%x %R")

cat > "$INSTALL_DIR/about.txt" <<EOF
Vocabulary Plus
Copyright (c) 2025 46Dimensions

Version: $VERSION_DISPLAY
Installed on: $DATE
Platform: MacOS
Developer: 46Dimensions

Website: https://github.com/46Dimensions/VocabularyPlus
License: Mit License. See $INSTALL_DIR/LICENSE for details.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF


# -------------------------------
# Remove 'installation' directory
# -------------------------------
cd "$INSTALL_DIR"
rm -r "$INSTALL_DIR/installation"

# Final message
echo ""
write_success "Vocabulary Plus $VERSION_DISPLAY installed successfully"
echo ""
echo "You can run Vocabulary Plus with the following commands:"
echo "  vocabularyplus"
echo "  vp"     
echo ""
echo "To use vp-vm (Vocabulary Plus Version Manager), see its help message:"
echo "  vp-vm --help"
echo ""
echo "To uninstall Vocabulary Plus, run:"
echo "  vocabularyplus uninstall"
echo ""
echo "If these don't work, open a new terminal or add this to PATH:"
echo "  $BIN_DIR"
echo ""