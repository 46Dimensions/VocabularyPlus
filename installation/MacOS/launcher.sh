#!/usr/bin/env sh
set -e

# -------------------
# Version information
# -------------------
VERSION="v2.0.0-beta4"
VERSION_DISPLAY="2.0.0 Beta 4"
DEVELOPMENT_BRANCH="2.0.0"

# Don't do anything with version or development branch
: "$VERSION $DEVELOPMENT_BRANCH"

# ANSI colours
red="\033[91m"
yellow="\033[93m"
reset="\033[0m"

# Check for venv in $INSTALL_DIR
if [ ! -d "$INSTALL_DIR/.venv" ]; then
    echo "${red}ERROR: Could not find VocabularyPlus venv directory at $INSTALL_DIR/.venv${reset}"
    exit 1
fi

# Handle subcommands
PY="$INSTALL_DIR/.venv/bin/python3"
case "$1" in
    uninstall)
        if ! [ "$2" = "-s" ] || [ "$2" = "--silent" ]; then
            echo "${yellow}Running uninstaller...${reset}"
        fi

        /usr/bin/env sh "$INSTALL_DIR/uninstall" "$2"
        exit $?
        ;;
    --help|-h)
        echo "Usage: vocabularyplus [options]"
        echo "Options:"
        echo "  uninstall [-s|--silent]    Uninstall Vocabulary Plus. Silent mode (-s|--silent) produces no output."
        echo "  -v, --version              Show version information"
        echo "  -a, --about                Show information about VocabularyPlus"
        echo "  -h, --help                 Show this help message"
        echo "Alias:"
        echo "  vp                         Shortcut for vocabularyplus"
        exit 0
        ;;
    --version|-v)
        echo "$VERSION_DISPLAY"
        exit 0
        ;;
    --about|-a)
        cat "$INSTALL_DIR/about.txt"
        ;;
    *)
        "$PY" "$INSTALL_DIR/app.py" "\$@"
        ;;
esac