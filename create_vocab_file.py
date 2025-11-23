#!/usr/bin/env python3
import colorama
import platform
import json
import time
import sys
import os

# Get the JSON_DIR constant
try:
    base_dir = os.path.dirname(os.path.abspath(__file__))
except NameError:
    # __file__ not defined (common on Windows double-click)
    base_dir = os.getcwd()

JSON_DIR = os.path.join(base_dir, "JSON")
os.makedirs(JSON_DIR, exist_ok=True)

# Initialise colorama (it will translate ANSI codes on Windows automatically)
colorama.init(autoreset=False)

# Print system information
print(f"Running with Python {platform.python_version()} on {platform.system()}. \nPress CTRL+C to quit. \n")

def on_keyboard_interrupt():
    """ Print a friendly goodbye message then exit with code 0. """
    print("\nThanks for using Vocabulary Plus. Goodbye!")
    sys.exit(0)

def clear_lines(lines: int) -> None:
    """
    Remove the lines from the terminal. \n
    :param lines: The number of lines to remove.
    """

    supports_ansi = sys.stdout.isatty() and os.getenv("TERM") not in (None, "dumb")

    if lines <= 0 or not supports_ansi:
        return

    # Move cursor up `lines` rows
    sys.stdout.write(colorama.Cursor.UP(lines))

    # Erase each line and move down one row
    for _ in range(lines):
        sys.stdout.write(colorama.ansi.clear_line())   # equivalent to "\033[K"
        sys.stdout.write("\n")

    # Return cursor to the starting line
    sys.stdout.write(colorama.Cursor.UP(lines))
    sys.stdout.flush()

def dynamic_input(text: str) -> str:
    """ 
    Print text with carriage return then ask the user for input. \n
    Fallback: print text normally then ask for input. \n

    Parameters
    ----------
    text : str
        The text to print before asking the user for input

    Returns
    -------
    str
        The user's input
    """
    try:
        # move to new line before input
        sys.stdout.write(f"\r{text}")
        sys.stdout.flush()
        user_input = input() # now input works normally
        return user_input
    except KeyboardInterrupt:
        on_keyboard_interrupt()
        sys.exit(0)
    except Exception:
        print(text, end="")
        user_input = input()
        return user_input

def load_json(filename) -> dict:
    """
    Return the contents of the JSON file `filename` as a dictionary

    Parameters
    ----------
    filename : str
        The JSON file to get the dictionary from

    Returns
    -------
    dict
        The dictionary found in the JSON file.   
        If there is no dictionary in the file, returns an empty dict.
    """
    if os.path.exists(filename):
        with open(filename, 'r', encoding='utf-8') as f:
            try:
                return dict(json.load(f))
            except json.JSONDecodeError:
                return {}
    return {}

def save_json(filename: str, data: dict) -> None:
    """
    Write the dictionary `data` to the JSON file `filename`

    Parameters
    ----------
    filename : str
        The filename of the JSON file to be written
    data : str
        The dictionary to be written into the JSON file
    """
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

def check_input(question) -> str:
    """
    Check if the user has entered something.   

    Parameters
    ----------
    message : str
        The question to be posed to the user.

    Returns
    -------
    str
        The input from the user
    """
    answer = input(question).strip()
    # If the input is nothing, tell the user and ask again
    while answer == "":
        print("Please enter something.")
        answer = input(question).strip()
    return answer

def main() -> None:
    """
    The main function which asks the user about the vocabulary file they are trying to create. \n
    Gets data such as the languages of the vocab, the number of words and the words and meanings themselves.
    """

    # The empty `data` dict
    data = {
        "languages": {},
        "words": {}
    }

    # Get the languages of the vocabulary
    learning = check_input("What language are you learning? ")
    spoken = check_input("What language do you speak? ")
    # Save the language data in `data["languages"]`
    data["languages"] = {
        "learning": learning,
        "spoken": spoken
    }

    def ask_num_words() -> str | bool:
        """ Get the number of words in the vocabulary file """
        valid = True
        
        def check():
            """ Check that the input is a number above 0 """
            # Set the `valid` variables
            nonlocal valid
            valid = True
            # Get the number of words from the user
            user_input = check_input("How many words are in the vocab list? ")

            # If it is not a digit, set `valid` to False
            if not user_input.isdigit():
                valid = False

            # If it is a digit, check if it is positive
            if valid == True:
                if int(user_input) <= 0:
                    valid = False

            return user_input # Return the number of words

        num_words = check()

        # If `num_words` is not valid, ask again
        while valid == False:
            print("Please enter a positive integer.")
            num_words = check()

        return num_words # Return the valid number of words
        
    num_words = ask_num_words()
    words = []

    # Get the first word and its meaning then add it to `words`
    lang1_word = dynamic_input(f"What is the first {learning} word in the vocab list? ")
    translated = dynamic_input(f"What is {lang1_word} in {spoken}? ")
    words.append([lang1_word, translated])
    time.sleep(0.5)
    clear_lines(2)

    # Get the other word/meaning pairs
    for i in range(int(num_words) - 1):
        lang1_word = dynamic_input(f"What is the next {learning} word in the vocab list? ")
        translated = dynamic_input(f"What is {lang1_word} in {spoken}? ")
        words.append([lang1_word, translated])
        time.sleep(0.5)
        clear_lines(2)

    # Append the items in `words` to `data`
    for i in range(len(words)):
        item1 = words[i][0] # The word in the foreign language
        item2 = words[i][1] # The word in the other language
        data["words"][item1] = item2 # `item1: item2`

    filename = check_input("What would you like the vocab file to be called? ") # The name the user desires for the JSON file

    # Check if the filename would work on Windows
    if platform.system() == "Windows":
        reserved = {"con","prn","aux","nul",
                *(f"com{i}" for i in range(1,10)),
                *(f"lpt{i}" for i in range(1,10))}

        if filename.lower() in reserved:
            print("That filename cannot be used on Windows.")
            return

    # Check if the filename ends in `.json`
    if filename.lower().endswith(".json"):
        has_file_extension = True
    else:
        has_file_extension = False

    # Set the absolute path of the file
    if has_file_extension == True:
        abs_path = os.path.join(JSON_DIR, filename)
    else:
        abs_path = os.path.join(JSON_DIR, f"{filename}.json")

    # Save the data into the JSON file
    save_json(abs_path, data)
    print(f"Saved as {abs_path}")

# Run the main loop
if __name__ == "__main__":
    main()