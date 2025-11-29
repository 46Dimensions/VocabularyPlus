#!/usr/bin/env python3
from typing import Tuple, Dict, Optional
from pathlib import Path
from colorama import init, Cursor, ansi, Fore, Style
import platform
import random
import json
import time
import sys
import os

# Initialise colorama (it will translate ANSI codes on Windows automatically)
init(autoreset=False)

# Print system information
print(f"{Fore.GREEN}Running with Python {platform.python_version()} on {platform.system()}.{Style.RESET_ALL}")
print(f"{Fore.GREEN}Vocabulary Plus Version: 1.0.0{Style.RESET_ALL}")
print(f"{Fore.RED}Press CTRL+C to quit.{Style.RESET_ALL}\n")
time.sleep(0.5)

# Get the JSON_DIR constant
try:
    base_dir = os.path.dirname(os.path.abspath(__file__))
except:
    # __file__ not defined
    base_dir = os.getcwd()

JSON_DIR = os.path.join(base_dir, "JSON")
os.makedirs(JSON_DIR, exist_ok=True)

class VocabFileError(Exception):
    """Custom exception indicating a problem with the vocabulary JSON file."""
    pass

def on_keyboard_interrupt():
    """ Print a friendly goodbye message then exit with code 0. """
    print(f"\n{Fore.LIGHTGREEN_EX}Thanks for using Vocabulary Plus. Goodbye!{Style.RESET_ALL}")
    sys.exit(0)

def get_jsons(dir: str) -> list:
    """
    Set a list to only JSON files in a directory \n
    :param dir: The directory to be scanned for JSON files
    """

    try:
        jsons = [f for f in os.listdir(dir)
                if f.lower().endswith('.json')
                and os.path.isfile(os.path.join(dir, f))]
    except Exception as e:
        jsons = []

    return jsons

jsons = get_jsons(JSON_DIR)

def read_json(path: str) -> Dict:
    """
    Load a JSON file and return its parsed contents.

    Parameters
    ----------
    path : str
        Filesystem path to the JSON document.

    Returns
    -------
    Dict
        The Python object resulting from  `json.load`.
    """
    with open(path, encoding="utf-8") as f:
        return dict(json.load(f))

def clear_lines(lines: int) -> None:
    """
    Remove the lines from the terminal. \n
    :param lines: The number of lines to remove.
    """

    supports_ansi = sys.stdout.isatty() and os.getenv("TERM") not in (None, "dumb")

    if lines <= 0 or not supports_ansi:
        return

    # Move cursor up `lines` rows
    sys.stdout.write(Cursor.UP(lines))

    # Erase each line and move down one row
    for _ in range(lines):
        sys.stdout.write(ansi.clear_line())   # equivalent to "\033[K"
        sys.stdout.write("\n")

    # Return cursor to the starting line
    sys.stdout.write(Cursor.UP(lines))
    sys.stdout.flush()

def dynamic_print(text: str):
    """
    Print text and leave cursor at the end. \n
    :param text: The text to print
    """

    try:
        sys.stdout.write(text + ("\n" if not text.endswith("\n") else ""))
        sys.stdout.flush()
    except KeyboardInterrupt:
        on_keyboard_interrupt()
    except Exception:
        print(text + ("\n" if not text.endswith("\n") else ""))

def dynamic_input(text: str) -> str:
    """ 
    Print text with carriage return then ask the user for input. \n
    Fallback: print text normally then ask for input. \n
    :param text: The text to print before asking the user for input
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

def get_display_filename(full_path: str, base_dir: str | None = None) -> str:
    """
    Return a clean, human-readable representation of *full_path* that works on any OS

    • If `base_dir` is supplied, the returned value is the path of
      `full_path` *relative* to that directory (otherwise the full
      absolute path is used). \n
    • The file extension (e.g. “.json”) is stripped. \n
    • Path separators are normalised to forward slashes for display purposes. \n

    Parameters
    ----------
    full_path: str
        The absolute or relative path to the file you want to display.
    base_dir: str | None, optional
        The directory that should be considered the root for the display.
        If omitted, the function simply shows the filename without its
        extension.

    Returns
    -------
    A platform-independent, extension-less path suitable for UI output *(str)*
    """

    # Turn everything into `pathlib.Path` objects (handles any OS)
    file_path = Path(full_path).expanduser()
    # try-except loop to catch Windows quirk
    try:
        file_path = file_path.resolve()
    except OSError:
        pass  # fall back to un-resolved path

    if base_dir is not None:
        base_path = Path(base_dir).expanduser().resolve()
        # try-except loop to catch Windows quirk
        try:
            file_path = file_path.resolve()
        except OSError:
            pass  # fall back to un-resolved path
    else:
        base_path = None

    # Compute a relative path if a base directory was given.
    #    If the file is not under `base_path` fall back to the
    #    absolute path – this prevents `ValueError: ... is not in the
    #    subpath of ...`.
    try:
        rel_path = file_path.relative_to(base_path) if base_path else Path(file_path.name)
    except Exception:
        # Not a sub‑path of base_path – just use the filename itself
        rel_path = file_path.name

    # Strip the file extension (e.g. ".json")
    stem = rel_path.with_suffix("")  # type: ignore - removes the suffix, keeps any remaining parts 

    # Normalise separators for display (always forward slash)
    display = str(stem).replace(os.sep, "/")

    return display

def get_dict_key(value: str, mapping: Dict[str, str]) -> str:
    """
    Reverse-lookup a key in a dictionary given a value.

    Parameters
    ----------
    value : str
        The value whose corresponding key we want.
    mapping : dict
        Dictionary where `value` is expected to appear among the values.

    Returns
    -------
    str
        The key that maps to `value`.

    Raises
    ------
    ValueError
        If the value is not found in the dictionary.
    """
    for k, v in mapping.items():
        if v == value:
            return k
        
    raise ValueError(f"Value {value!r} not found in dictionary.")

def get_file_number() -> int:
    """
    Get the file that the user wants to be tested on.
    Returns the vocab file # in the list of vocab files printed.
    """

    # Print heading
    print(f"{Fore.LIGHTBLUE_EX}Vocabulary Files{Style.RESET_ALL}")
    time.sleep(1)

    if jsons:
        # Print the list
        for i in range(len(jsons)):
            display_name = get_display_filename(jsons[i])
            print(f"{Fore.YELLOW}{i + 1}.{Style.RESET_ALL} {display_name}")

        failed = False
        def check() -> str:
            """
            Ask for input, then check if the input is a positive integer.
            Returns the input.
            """
            nonlocal failed
            user_input = input(f"{Fore.BLUE}Choose one of the above vocab lists: {Style.RESET_ALL}")
            failed = False
            if not user_input.isdigit():
                failed = True
                print(f"{Fore.YELLOW}Please enter an integer{Style.RESET_ALL}")
            
            if failed == False:
                if int(user_input) > len(jsons) or int(user_input) < 1:
                    failed = True
                    print(f"{Fore.YELLOW}Please enter an integer between 1 and {len(jsons)}.{Style.RESET_ALL}") # type: ignore

            return user_input

        chosen_file = check()

        # Keep asking until it is a positive integer
        while failed == True:
            chosen_file = check()

        return int(chosen_file)
    else:
        # If `jsons` doesn't exist, return 0
        # This should not happen as the script exits
        return 0
    
def get_question(json_file: str) -> Tuple[str, str, str]:
    """
    Load a vocabulary JSON file and generate a single question.

    The function randomly picks either the language the user is learning
    or the language they already speak, then selects a random word from the
    appropriate side of the vocabulary mapping.

    Parameters
    ----------
    json_file: str
        Path to the JSON file containing the language and word data.

    Returns
    -------
    Tuple[str, str, str]
        A three-element tuple:
        1. `question` The formatted question string.
        2. `word`  The word that appears in the question.
        3. `word_type` Either `"keys"` (the word is from the learning
           language) or `"values"` (the word is from the spoken language).

    Raises
    ------
    VocabFileError
        If the JSON structure is malformed or missing expected keys.
    """

    # Load the JSON data into a dictionary.
    data = dict(read_json(json_file))

    # Helper: Choose which language (learning vs. spoken) to ask about.
    def get_language() -> Tuple[str, str, str]:
        """
        Randomly pick one of the two languages defined in the JSON file.

        Returns
        -------
        Tuple[str, str, str]
            (`selected_language`, `other_language`, `word_type`)
            * `selected_language` - The language that will be used for the
              answer side of the question.
            * `other_language` - The opposite language (used in the
              question text).
            * `word_type` - `"keys"` if the selected language is
              the learning language, otherwise `"values"`.
        """
        # Extract the two language entries from the JSON.
        languages = [
            data["languages"]["learning"],
            data["languages"]["spoken"]
        ]

        # Randomly choose either the learning or spoken language.
        selected = random.choice(languages)

        # Determine which side of the vocab dict we’ll pull words from.
        if selected == languages[0]:          # learning language chosen
            word_type = "keys"
            other_language = languages[1]    # spoken language
        else:                                 # spoken language chosen
            word_type = "values"
            other_language = languages[0]    # learning language

        return selected, other_language, word_type

    # Helper: Build the human‑readable question string.
    def formulate_question(
        language: str,
        word: str,
        lang_info: str
    ) -> str:
        """
        Create a question based on the supplied language, word, and context.

        Parameters
        ----------
        language : str
            The language that the *answer* will be in (the opposite of the
            language shown in the question).
        word : str
            The word to be queried.
        lang_info : str
            Either `"learning"` (the user is learning this language) or
            `"spoken"` (the user already speaks this language). Determines
            the phrasing of the question.

        Returns
        -------
        str
            The formatted question.
        """
        if lang_info == "learning":
            # Asking for the meaning of a word in the language being learned.
            return f"What does '{word}' mean in {language}?"
        else:
            # Asking for the translation of a known word into the learning language.
            return f"What is '{word}' in {language}?"

    # Main flow: pick language, fetch a random word, build the question.
    selected_lang, other_lang, word_type = get_language()

    # Pull the appropriate side of the vocab mapping (keys vs. values).
    try:
        if word_type == "keys":
            # Keys correspond to words in the learning language.
            word_list = list(dict(data["words"]).keys())
        elif word_type == "values":
            # Values correspond to words in the spoken language.
            word_list = list(dict(data["words"]).values())
        else:
            # This should never happen, but we guard against corrupted data.
            raise VocabFileError("malformed vocabulary file")
    except Exception as exc:
        # Re‑raise a consistent error type for callers.
        raise VocabFileError("malformed vocabulary file.") from exc

    # Randomly select a word from the chosen side.
    word = random.choice(word_list)

    # Translate the internal `word_type` into a human‑readable label.
    lang_info = "learning" if word_type == "keys" else "spoken"

    # Assemble the final question string.
    question = formulate_question(other_lang, word, lang_info)

    # Return everything the caller needs to present the quiz item.
    return question, word, word_type

def check_answer(
    question_word: str,
    user_input: str,
    data_file: str,
    question_word_location: str,
) -> Tuple[bool, str|None]:
    """
    Verify whether the user's answer matches the expected translation.

    The function reads the vocabulary JSON file, determines where the
    `question_word` lives (as a key or a value), retrieves the correct
    answer, and compares it to the supplied `user_input`.

    Parameters
    ----------
    question_word : str
        The word that appeared in the generated question (either a key or a value
        depending on `question_word_location`).
    user_input : str
        The answer supplied by the user.
    data_file : str
        Path to the JSON file that contains the `words` mapping.
    question_word_location : str
        Either `"keys"` if `question_word` is a key in the vocab dict,
        or `"values"` if it is a value. Anything else raises `ValueError`.

    Returns
    -------
    Tuple[bool, str]
        `(is_correct, correct_answer)` where:
        * `is_correct` - `True` if `user_input` exactly matches the
          expected answer, `False` otherwise.
        * `correct_answer` - The answer that should have been provided.

    Raises
    ------
    VocabFileError
        If the JSON structure is malformed or the expected word cannot be
        located in the vocabulary mapping.
    ValueError
        If `question_word_location` is not `"keys"` nor `"values"`,
        or if a reverse lookup fails.
    """
    # Load the JSON file and isolate the `words` dictionary.
    raw_data = dict(read_json(data_file))          # top‑level JSON object
    vocab: Dict[str, str] = dict(raw_data["words"])  # mapping of learning↔spoken

    # Resolve the correct answer based on where the question word lives.
    try:
        if question_word_location == "keys":
            # The question word is a key; the answer is the corresponding value.
            answer = vocab[question_word]
        elif question_word_location == "values":
            # The question word is a value; we need the matching key.
            answer = get_dict_key(question_word, vocab)
        else:
            # Guard against accidental misuse.
            raise ValueError(
                "parameter 'question_word_location' must be 'keys' or 'values'"
            )
    except KeyError as exc:
        # `question_word` wasn’t found where we expected it.
        raise VocabFileError("answer not in vocab file.") from exc

    # Compare the user’s input with the expected answer.
    is_correct = user_input == answer
    return is_correct, answer

def main() -> None:
    """
    Run the interactive Vocabulary Plus session.

    The function prints a brief header, lets the user select a vocabulary
    file, and then enters an infinite loop that repeatedly asks questions
    until the user aborts with Ctrl-C.
    """
    def ask_question(vocab_file: str) -> None:
        """
        Pose a single vocabulary question to the user and report the result.

        Parameters
        ----------
        vocab_file : str
            Filename (relative to `JSON_DIR`) of the JSON file that contains the
            `words` mapping and language metadata.
        """
        # Build the absolute path to the JSON file.
        json_path = os.path.join(JSON_DIR, vocab_file)
         
        # Generate a random question.
        question_text, question_word, word_location = get_question(json_path)

        # Prompt the user and capture their answer.
        user_answer = dynamic_input(f"{Fore.MAGENTA}{question_text} {Style.RESET_ALL}")
         
        # Verify the answer.
        is_correct, correct_answer = check_answer(
            question_word,
            user_answer,
            json_path,
            word_location,
        )

        # Give feedback
        if is_correct:
            dynamic_print(f"{Fore.GREEN}Correct.{Style.RESET_ALL}")
        else:
            dynamic_print(f"{Fore.RED}Incorrect. Correct answer: {correct_answer}{Style.RESET_ALL}")

        # Pause briefly so the user can read the feedback, then clean up the terminal lines that were printed for the question/answer.
        time.sleep(3)
        clear_lines(2)

    # --------------------------- Header --------------------------------
    print(f"{Fore.CYAN}Vocabulary Plus{Style.RESET_ALL}")
    print("A CLI foreign vocabulary learning tool.")
    print("Learn more at https://github.com/46Dimensions/VocabularyPlus.\n")
    time.sleep(2)

    # ----------------------- Choose a vocab file -----------------------
    chosen_file_number = get_file_number()

    # `0` signals that no files were found (see `get_file_number` impl.).
    if chosen_file_number == 0:
        print(f"{Fore.YELLOW}It seems like there are no vocabulary files.{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}Use the vocab file creator ('vocabularyplus create') to make one!{Style.RESET_ALL}")
        time.sleep(5)
        sys.exit(0)

    # Resolve the actual filename from the global `jsons` list.
    vocab_file: Optional[str] = (
        jsons[chosen_file_number - 1] if jsons else None
    )

    # If for some reason `jsons` is empty (shouldn't happen after the check above), fall back to `None` and later exit gracefully.
    if not vocab_file:
        print(f"{Fore.YELLOW}Unable to locate the selected vocabulary file.{Style.RESET_ALL}")
        sys.exit(1)

    # --------------------------- Question UI ---------------------------
    print(f"\n{Fore.YELLOW}Question{Style.RESET_ALL}")

    # --------------------------- Loop ----------------------------------
    try:
        while True:
            ask_question(vocab_file)
    except KeyboardInterrupt:
        on_keyboard_interrupt()
        sys.exit(0)
        
try:
    main()
except KeyboardInterrupt:
    on_keyboard_interrupt()
except Exception as e:
    print(f"{Fore.RED}Error: .{Style.RESET_ALL}")
    print(f"{Fore.LIGHTBLUE_EX}Report it at https://github.com/46Dimensions/VocabularyPlus/issues/new. {Style.RESET_ALL}")
    time.sleep(10)
    sys.exit(1)