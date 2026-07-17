import json
from pathlib import Path


def read_vocab_file(filename: str|Path) -> dict:
    with open(filename, "r") as file:
        dictionary = json.load(file)
        return dictionary
    
def write_vocab_file(filename: str|Path, data: dict):
    with open(filename, "x") as file:
        json.dump(data, file)