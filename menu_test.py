from blessed import Terminal
import curses
import time

menu_items = ["Option 1", "Option 2", "Option 3", "Option 4"]
selected_index = 0
term = Terminal()

SPECIAL_KEYS = {
    "\x1b[A": "UP",
    "\x1b[B": "DOWN",
    "\x1b[C": "RIGHT",
    "\x1b[D": "LEFT",
    "\n": "ENTER"
}

def draw_menu():
    print(term.clear)
    h, w = term.height, term.width

    for idx, item in enumerate(menu_items):
        x = 2
        y = idx
        if idx == selected_index:
            print(term.move_xy(x,y) + term.red_on_white(term.red(f"> {item}")))
        else:
            print(term.move_xy(x,y) + f"  {item}")

    print(term.move_xy(0, h - 1) + "Use ↑/↓ or k/j to move, Enter to select, q/Esc to quit", end='', flush=True)

def getch(timeout: int|None = None) -> str:
    with term.cbreak():
        key = term.inkey(timeout = timeout)
        key_str = str(key)
        if key_str in SPECIAL_KEYS:
            key_str = SPECIAL_KEYS[key_str]

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
        elif key in ("ENTER"):
            print(term.move_xy(0, len(menu_items) + 1) + f"You selected {menu_items[selected_index]}")
            time.sleep(5)
            break
        elif key == "Q":
            break

def key_test():
    with term.cbreak():
        while True:
            key = term.inkey()

            key_str = str(key)

            if key_str in SPECIAL_KEYS:
                print(f"You pressed the {SPECIAL_KEYS[key_str].lower()} key")
            elif key_str == 'q':
                print("Exiting...")
                break
            else:
                print(f"You pressed '{key_str}'")

if __name__ == "__main__":
    with term.fullscreen():
        print(term.hide_cursor, end='')
        #curses.wrapper(main)
        key_test()
        main()
        print(term.show_cursor, end='')