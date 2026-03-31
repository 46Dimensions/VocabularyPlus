import curses

def up_arrow(stdscr):
    stdscr.erase()
    stdscr.addstr()

def down_arrow(stdscr):
    pass

def main(stdscr):
    curses.curs_set(0)          # Hide cursor
    stdscr.keypad(True)         # Enable special keys

    while True:
        key = stdscr.getch()

        if key == curses.KEY_UP:
            up_arrow(stdscr)
        elif key == curses.KEY_DOWN:
            down_arrow(stdscr)
        #elif key == curses.KEY_LEFT:
            
        #elif key == curses.KEY_RIGHT:
        #   stdscr.addstr(0, 0, "Right arrow")
        #elif key == ord('q'):
        #    break

        stdscr.refresh()

curses.wrapper(main)