import curses

menu_items = ["Option 1", "Option 2", "Option 3", "Option 4"]
selected_index = 0

def draw_menu(stdscr):
    stdscr.erase()
    h, w = stdscr.getmaxyx()

    for idx, item in enumerate(menu_items):
        x = 2
        y = idx + 2
        if idx == selected_index:
            stdscr.attron(curses.color_pair(1))
            stdscr.addstr(y, x, f"> {item}")
            stdscr.attroff(curses.color_pair(1))
        else:
            stdscr.addstr(y, x, f"  {item}")

    stdscr.addstr(h - 2, 2, "Use ↑/↓ or k/j to move, Enter to select, q/Esc to quit")
    stdscr.refresh()

def main(stdscr):
    global selected_index
    curses.curs_set(0)
    stdscr.keypad(True)

    if not curses.has_colors():
        raise RuntimeError("Terminal does not support colors")

    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_RED, -1)

    while True:
        draw_menu(stdscr)
        key = stdscr.getch()

        if key in (curses.KEY_UP, ord('w')):
            selected_index = max(0, selected_index - 1)
        elif key in (curses.KEY_DOWN, ord('s')):
            selected_index = min(len(menu_items) - 1, selected_index + 1)
        elif key in (curses.KEY_ENTER, 10, 13):
            stdscr.addstr(len(menu_items) + 3, 2, f"You selected: {menu_items[selected_index]} " + " " * 20)
            stdscr.refresh()
            stdscr.getch()
            break
        elif key in (ord('q'), 27):
            break

if __name__ == "__main__":
    curses.wrapper(main)