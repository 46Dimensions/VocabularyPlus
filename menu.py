from blessed import Terminal
from pathlib import Path
import subprocess
import platform
import time
import os

ON_WINDOWS = platform.system().lower() == "windows"

bin_dir_file = Path(os.path.dirname(__file__)) / ".bin_dir.txt"
bin_dir = bin_dir_file.read_text().strip()

menu_items = ["Learn vocab", "Create a vocabulary file", "About Vocabulary Plus"]
menu_descriptions = ["Opening Vocabulary Plus...", "Opening vocab file creator", "Opening About screen"]

if ON_WINDOWS:
    commands = ['', 'create', '--version']
else:
    commands = [os.path.join(bin_dir, "vocabularyplus"), f"{os.path.join(bin_dir, "vocabularyplus")} create", f"{os.path.join(bin_dir, "vocabularyplus")} --version"]

selected_index = 0
term = Terminal()

HIDE_CURSOR = "\x1b[?25l"
SHOW_CURSOR = "\x1b[?25h"
SPECIAL_KEYS = {
    "\x1b[A": "UP",
    "\x1b[B": "DOWN",
    "\x1b[C": "RIGHT",
    "\x1b[D": "LEFT",
    "codes": {
        term.KEY_ENTER: "ENTER",
        term.KEY_ESCAPE: "ESC"
    }
}

def draw_menu():
    print(term.home, end='')
    h, w = term.height, term.width

    for idx, item in enumerate(menu_items):
        x = 2
        y = idx
        if idx == selected_index:
            print(term.move_xy(x,y) + term.bold(term.red(f"> {item}")))
        else:
            print(term.move_xy(x,y) + f"  {item}")

    print(term.move_xy(0, h - 1) + "Use ↑/↓ or w/s to move, Enter to select, q/esc to quit", end='', flush=True)

def getch(timeout: int|None = None) -> str:
    with term.cbreak():
        key = term.inkey(timeout = timeout)
        key_str = str(key)

        if key_str in SPECIAL_KEYS:
            key_str = SPECIAL_KEYS[key_str]
        elif key.code in SPECIAL_KEYS["codes"]:
            key_str = SPECIAL_KEYS["codes"][key.code]
            
        return key_str.upper()

def main():
    global selected_index

    while True:
        draw_menu()
        key = getch()

        if key in ("UP", "W"):
            selected_index = max(0, selected_index - 1)
        elif key in ("DOWN", "S"):
            selected_index = min(len(menu_items) - 1, selected_index + 1)
        elif key == "ENTER":
            print(term.move_xy(0, len(menu_items) + 1) + menu_descriptions[selected_index])
            time.sleep(2)
            break
        elif key in ("Q", "ESC"):
            break

if __name__ == "__main__":
    try:
        print(HIDE_CURSOR, end='')
        with term.fullscreen():
            main()

        print(SHOW_CURSOR, end='', flush=True)
        if not ON_WINDOWS:
            subprocess.run(commands[selected_index], shell=True)
        else:
            subprocess.run(['powershell', '-File', os.path.join(bin_dir, "vocabularyplus.ps1"), commands[selected_index]])
    except KeyboardInterrupt:
        print(SHOW_CURSOR, end='', flush=True)
    finally:
        print(SHOW_CURSOR, end='', flush=True)