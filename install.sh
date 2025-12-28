#!/usr/bin/env sh
set -e

# ANSI colours
red="\033[91m"
green="\033[92m"
yellow="\033[93m"
cyan="\033[1;96m"
reset="\033[0m"

# Disable stdout if $1 is -s or --silent
SILENT=0
case "$1" in
  -s|--silent) SILENT=1 ;;
esac

if [ "$SILENT" -eq 1 ]; then
  exec >/dev/null
fi

echo "${cyan}============================================${reset}"
echo "${cyan}Vocabulary Plus: Unix Installer (1.3.0)${reset}"
echo "${cyan}============================================${reset}"
echo

BASE_URL="https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/1.3.0"
REQ_URL="$BASE_URL/requirements.txt"
MAIN_URL="$BASE_URL/main.py"
CREATE_URL="$BASE_URL/create_vocab_file.py"
ICON_URL="$BASE_URL/app_icon.png"
VP_VM_INSTALLER_URL="https://raw.githubusercontent.com/46Dimensions/vp-vm/main/install-vm.sh"

check_python() {
    command -v python3 >/dev/null 2>&1 || {
        echo "${red}ERROR: Python3 not found. Please install Python 3.10+.${reset}"
        exit 1
    }

    PYVER=$(python3 --version 2>&1 | awk '{print $2}')
    MAJOR=$(printf "%s" "$PYVER" | cut -d. -f1)
    MINOR=$(printf "%s" "$PYVER" | cut -d. -f2)

    if [ "$MAJOR" -lt 3 ] || { [ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 10 ]; }; then
        echo "${red}ERROR: Python must be >= 3.10 (found $PYVER).${reset}"
        exit 1
    fi
}

check_for_installation() {
    if [ -f "$HOME/.local/bin/vocabularyplus" ]; then
        echo "${red}ERROR: Vocabulary Plus appears to be already installed.${reset}"
        exit 1
    fi
}

check_python
check_for_installation

INSTALL_DIR="$PWD/VocabularyPlus"

echo "${yellow}Creating VocabularyPlus directory at $INSTALL_DIR...${reset}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || { echo "${red}Failed to enter VocabularyPlus directory${reset}"; exit 1; }

echo "${yellow}Downloading files...${reset}"
curl -fsSL "$REQ_URL" -o requirements.txt || { echo "${red}Failed to download requirements.txt${reset}"; exit 1; }
curl -fsSL "$MAIN_URL" -o main.py || { echo "${red}Failed to download main.py${reset}"; exit 1; }
curl -fsSL "$CREATE_URL" -o create_vocab_file.py || { echo "${red}Failed to download create_vocab_file.py${reset}"; exit 1; }
curl -fsSL "$ICON_URL" -o app_icon.png || { echo "${red}Failed to download icon${reset}"; exit 1; }

echo "${yellow}Creating virtual environment...${reset}"
python3 -m venv venv || { echo "${red}Failed to create venv${reset}"; exit 1; }

PY="$INSTALL_DIR/venv/bin/python3"

echo "${yellow}Upgrading pip...${reset}"
"$PY" -m pip install --upgrade pip

echo "${yellow}Installing dependencies...${reset}"
"$PY" -m pip install -r requirements.txt
rm requirements.txt

# Create portable launcher in ~/.local/bin
LAUNCHER="$HOME/.local/bin/vocabularyplus"
mkdir -p "$(dirname "$LAUNCHER")"

echo "${yellow}Creating launcher script at $LAUNCHER...${reset}"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env sh
set -e

# Check for venv in $INSTALL_DIR
if [ -d "$INSTALL_DIR/venv" ]; then
    BASE_DIR="$INSTALL_DIR"
else
    echo "ERROR: Could not find VocabularyPlus directory at $INSTALL_DIR"
    exit 1
fi

# Handle --version flag
if [ "\$1" = "--version" ] || [ "\$1" = "-v" ]; then
    echo 1.3.0
    exit 0
fi

# Handle --help flag
if [ "\$1" = "--help" ]; then
    echo "Usage: vocabularyplus [create] [options]"
    echo "Commands:"
    echo "  create                     Create a new vocabulary file"
    echo "  uninstall [-s|--silent]    Uninstall Vocabulary Plus. Silent mode (-s|--silent) produces no output."
    echo "Options:"
    echo "  -v, --version              Show version information"
    echo "  --help                     Show this help message"
    echo "Alias:"
    echo "  vp                         Shortcut for vocabularyplus"
    exit 0
fi

# Handle uninstall subcommand
if [ "\$1" = "uninstall" ]; then
    if [ "\$2" = "-s" ] || [ "\$2" = "--silent" ]; then
        /usr/bin/env sh $INSTALL_DIR/uninstall "\$2"
    else
        echo "${yellow}Running uninstaller...${reset}"
        /usr/bin/env sh $INSTALL_DIR/uninstall
    fi
    exit \$?
fi

# Handle create subcommand
PY="$INSTALL_DIR/venv/bin/python3"
case "\$1" in
  create)
    shift
    "\$PY" "$INSTALL_DIR/create_vocab_file.py" "\$@"
    ;;
  *)
    "\$PY" "$INSTALL_DIR/main.py" "\$@"
    ;;
esac
EOF
chmod +x "$LAUNCHER"

# Create uninstall script in $INSTALL_DIR
UNINSTALLER="$INSTALL_DIR/uninstall"
echo "${yellow}Creating uninstaller script at $UNINSTALLER...${reset}"
cat > "$UNINSTALLER" <<EOF
#!/usr/bin/env sh
set -e

# Disable stdout if '\$1' is -s or --silent
SILENT=0
case "\$1" in
  -s|--silent) SILENT=1 ;;
esac

if [ "\$SILENT" -eq 1 ]; then
  exec >/dev/null
fi

echo "${green}==============================================${reset}"
echo "${green}Vocabulary Plus: Unix Uninstaller (1.3.0)${reset}"
echo "${green}==============================================${reset}"

cd $INSTALL_DIR || { echo "${red}Failed to enter VocabularyPlus directory${reset}"; exit 1; }
deactivate 2>/dev/null || true

echo "${yellow}Removing VocabularyPlus installation...${reset}"
# Remove files
rm -f main.py create_vocab_file.py app_icon.png requirements.txt
# Remove directories
rm -rf JSON 2>/dev/null || true
rm -rf venv 2>/dev/null || true
echo "${green}VocabularyPlus files & directories removed.${reset}"

# Remove launchers
echo "${yellow}Removing launchers...${reset}"
rm -f "$HOME/.local/bin/vocabularyplus" 2>/dev/null || true
rm -f "$HOME/.local/bin/vp" 2>/dev/null || true
rm -f "$HOME/.local/bin/vp-vm 2>/dev/null" || true
echo "${green}Launchers removed.${reset}"

# Remove Linux .desktop entry
if [ "$(uname)" = "Linux" ]; then
    echo "${yellow}Removing .desktop entry...${reset}"
    rm -f "$HOME/.local/share/applications/vocabularyplus.desktop" 2>/dev/null || true
    echo "${green}Linux desktop entry removed.${reset}"
fi

# Remove macOS .app bundle
if [ "$(uname)" = "Darwin" ]; then
    echo "${yellow}Removing macOS .app bundle...${reset}"
    APP_BUNDLE="$HOME/Applications/VocabularyPlus.app"
    rm -rf "$APP_BUNDLE" 2>/dev/null || true
    echo "${green}macOS .app bundle removed.${reset}"
fi

echo ""
echo "${green}Uninstallation complete.${reset}"
echo "${yellow}If you found any errors in Vocabulary Plus, please report them at https://github.com/46Dimensions/VocabularyPlus/issues ${reset}"
# Remove VocabularyPlus directory
cd .. || { exit 1; }
rm -rf VocabularyPlus 2>/dev/null || true
rm install.sh 2>/dev/null || true
EOF
chmod +x "$UNINSTALLER"

# Create alias symlink "vp"
ALIAS="$HOME/.local/bin/vp"
ln -sf "$LAUNCHER" "$ALIAS"

# LINUX: Create .desktop launcher
if [ "$(uname)" = "Linux" ]; then
    echo "${yellow}Creating Linux desktop entry...${reset}"

    DESKTOP_FILE="$HOME/.local/share/applications/vocabularyplus.desktop"
    mkdir -p "$(dirname "$DESKTOP_FILE")"

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Vocabulary Plus
Exec=$LAUNCHER
Icon=$INSTALL_DIR/app_icon.png
Terminal=true
Categories=Education;
EOF

    chmod +x "$DESKTOP_FILE"
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
    echo "${green}Linux app icon installed successfully.${reset}"
fi

# macOS: Create .app bundle
if [ "$(uname)" = "Darwin" ]; then
    echo "${yellow}Creating macOS .app bundle...${reset}"

    APP_DIR="$HOME/Applications/Vocabulary Plus.app"
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"

    # Copy icon & convert to .icns if sips exists
    cp "$INSTALL_DIR/app_icon.png" "$APP_DIR/Contents/Resources/app_icon.png"
    if command -v sips >/dev/null 2>&1; then
        sips -s format icns "$APP_DIR/Contents/Resources/app_icon.png" --out "$APP_DIR/Contents/Resources/app_icon.icns" >/dev/null 2>&1 || true
    fi

    # Launcher wrapper
    cat > "$APP_DIR/Contents/MacOS/vocabularyplus" <<EOF
#!/bin/bash
"$LAUNCHER"
EOF
    chmod +x "$APP_DIR/Contents/MacOS/vocabularyplus"

    # Info.plist
    cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleName</key><string>Vocabulary Plus</string>
    <key>CFBundleExecutable</key><string>vocabularyplus</string>
    <key>CFBundleIdentifier</key><string>com.vocabularyplus.app</string>
    <key>CFBundleIconFile</key><string>app_icon.icns</string>
  </dict>
</plist>
EOF

    echo "${green}macOS .app installed: $APP_DIR${reset}"
fi

# Install Vocabulary Plus Version Manager
echo "${yellow}Installing Vocabulary Plus Version Manager...${reset}"
# Download file
echo "${yellow}Downloading installer...${reset}"
curl -fsSL "$VP_VM_INSTALLER_URL" -o install-vm.sh || { echo "${red}Failed to download VP VM installer${reset}"; exit 1; }
echo "${green}Download complete.${reset}"
# Run installer
echo "${yellow}Running VP VM installer...${reset}"
sh install-vm.sh $INSTALL_DIR/vm || { echo "${red}Failed to install VP VM${reset}"; exit 1; }
# Remove installer
rm install-vm.sh

# Set Vocabulary Plus version file
echo "1.3.0" > $INSTALL_DIR/vm/versions/vp/current.txt

# Final message
echo ""
echo "${green}Vocabulary Plus 1.3.0 installed successfully${reset}"
echo ""
echo "You can run Vocabulary Plus with the following commands:"
echo "  vocabularyplus           main application"
echo "  vocabularyplus create    to create a new vocabulary file"
echo "  vp                       shortcut for main application"
echo "  vp create                shortcut to create a new vocabulary file"
echo ""
echo "To use vp-vm (Vocabulary Plus Version Manager), see its help message:"
echo "  vp-vm --help"
echo ""
echo "To uninstall Vocabulary Plus, run:"
echo "  vocabularyplus uninstall"
echo ""
echo "If these don't work, add this to PATH:"
echo "  $HOME/.local/bin"
echo ""
