#!/usr/bin/env sh
set -e

# ANSI colours
red="\033[91m"
green="\033[92m"
yellow="\033[93m"
reset="\033[0m"

# Disable stdout if '$1' is -s or --silent
SILENT=0
case "$1" in
  -s|--silent) SILENT=1 ;;
esac

if [ "$SILENT" -eq 1 ]; then
  exec >/dev/null
fi

# Enter install directory
cd "$INSTALL_DIR" || { echo "${red}Failed to enter VocabularyPlus directory${reset}"; exit 1; }
# Exit venv
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

# Remove .app bundle
echo "${yellow}Removing macOS .app bundle...${reset}"
APP_BUNDLE="$HOME/Applications/VocabularyPlus.app"
rm -rf "$APP_BUNDLE" 2>/dev/null || true
echo "${green}macOS .app bundle removed.${reset}"

# Remove VocabularyPlus directory
cd .. || { exit 1; }
rm -rf VocabularyPlus 2>/dev/null

echo ""
echo "${green}Uninstallation complete.${reset}"
echo "${yellow}If you found any errors in Vocabulary Plus, please report them at https://github.com/46Dimensions/VocabularyPlus/issues ${reset}"