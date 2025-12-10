#!/usr/bin/env sh
set -e

# ANSI colours
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset="\033[0m"

echo "${green}====================================${reset}"
echo "${green}Vocabulary Plus Unix Installer 1.0.2${reset}"
echo "${green}====================================${reset}"
echo

BASE_URL="https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main"
REQ_URL="$BASE_URL/requirements.txt"
MAIN_URL="$BASE_URL/main.py"
CREATE_URL="$BASE_URL/create_vocab_file.py"
ICON_URL="$BASE_URL/app_icon.png"

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

check_python

INSTALL_DIR="$HOME/VocabularyPlus"

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
cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env sh
if [ -d "$HOME/VocabularyPlus/venv" ]; then
    BASE_DIR="$HOME/VocabularyPlus"
else
    echo "ERROR: Could not find VocabularyPlus directory at \$HOME/VocabularyPlus"
    exit 1
fi
PY="$BASE_DIR/venv/bin/python3"
case "$1" in
  create)
    shift
    "$PY" "$BASE_DIR/create_vocab_file.py" "$@"
    ;;
  *)
    "$PY" "$BASE_DIR/main.py" "$@"
    ;;
esac
EOF

chmod +x "$LAUNCHER"

# Create alias symlink "vp"
ALIAS="$HOME/.local/bin/vp"
ln -sf "$LAUNCHER" "$ALIAS"

##############################################
# LINUX: Create .desktop launcher
##############################################
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
Terminal=false
Categories=Education;
EOF

    chmod +x "$DESKTOP_FILE"

    update-desktop-database ~/.local/share/applications 2>/dev/null || true

    echo "${green}Linux app icon installed successfully.${reset}"
fi

##############################################
# macOS: Create .app bundle
##############################################
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

echo
echo "${green}Vocabulary Plus 1.0.2 installed successfully${reset}"
echo "You can now run:"
echo "  vocabularyplus"
echo "  vocabularyplus create"
echo "  vp"
echo "  vp create"
echo
echo "Make sure ~/.local/bin is in your PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""