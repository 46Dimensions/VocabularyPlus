#!/usr/bin/env sh
set -e

# ANSI colours
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
reset="\033[0m"

echo "${green}==============================${reset}"
echo "${green}Vocabulary Plus Unix Installer${reset}"
echo "${green}==============================${reset}"
echo

BASE_URL="https://raw.githubusercontent.com/46Dimensions/VocabularyPlus/main"
REQ_URL="$BASE_URL/requirements.txt"
MAIN_URL="$BASE_URL/main.py"
CREATE_URL="$BASE_URL/create_vocab_file.py"

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

echo "${yellow}Creating virtual environment...${reset}"
python3 -m venv venv || { echo "${red}Failed to create venv${reset}"; exit 1; }

PY="$INSTALL_DIR/venv/bin/python3"

echo "${yellow}Upgrading pip...${reset}"
"$PY" -m pip install --upgrade pip

echo "${yellow}Installing dependencies...${reset}"
"$PY" -m pip install -r requirements.txt
# Remove the requirements.txt file after installation
rm requirements.txt

# Create portable launcher in ~/.local/bin
LAUNCHER="$HOME/.local/bin/vocabularyplus"
mkdir -p "$(dirname "$LAUNCHER")"

echo "${yellow}Creating launcher script at $LAUNCHER...${reset}"
cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env sh
# Determine the real directory of this script
SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
# Assume VocabularyPlus is in the same parent directory as this launcher

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

echo
echo "${green}Installation complete!${reset}"
echo "You can now run:"
echo "  vocabularyplus           # Runs main.py"
echo "  vocabularyplus create    # Runs create_vocab_file.py"
echo
echo "Make sure ~/.local/bin is in your PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""