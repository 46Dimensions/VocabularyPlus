from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, VerticalScroll
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Label, Static

from vocab_io import read_vocab_file, write_vocab_file

filedir = Path(__file__).parent # ~/.vp-vm/versions/<version>
datadir = filedir.parent.parent / "data" # ~/.vp-vm/data

class VocabularyRow(Horizontal):
    CSS = filedir / "VocabularyPlus.tcss"

    def __init__(self, word: str = "", translation: str = "", id: str|None = None, delete_button: bool = True, placeholders: tuple["str", str] = ("Enter word here", "Enter translation here")):
        super().__init__(id=id if id else None)
        self.word = word
        self.translation = translation
        self.delete_button = delete_button
        self.word_placeholder, self.translation_placeholder = placeholders

    def compose(self) -> ComposeResult:
        yield Input(self.word, classes="word", placeholder=self.word_placeholder)
        yield Input(self.translation, classes="translation", placeholder=self.translation_placeholder)

        if self.delete_button:
            yield Button("✖", classes="delete", variant="error", flat=True)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.has_class("delete"):
            self.remove()

class SaveFileScreen(ModalScreen):
    CSS_PATH = filedir / "VocabularyPlus.tcss"

    def __init__(self, json: dict):
        super().__init__()
        self.json = json
        self.dir = datadir / "vocab"
        self.file = Path()

    def compose(self) -> ComposeResult:
        with Container(id="save-file-screen"):
            yield Label("Save Vocabulary File", classes="title")
            yield Label("Filename:")
            yield Input(placeholder="Enter filename", id="save-file-filename-input")
            yield Label("Folder:")
            yield Input(value=str(self.dir), placeholder="Enter folder name", id="save-file-directory-input")

            with Horizontal(id="save-file-screen-buttons"):
                yield Button("💾 Save", flat=True, classes="green", id="save-file-save-button")
                yield Button("🗑  Don't Save", flat=True, classes="red", id="save-file-dont-save-button")
                yield Button("✖ Cancel", flat=True, classes="orange", id="save-file-cancel-button")

            yield Label(id="confirmation-label")

    def on_input_submitted(self, event: Input.Submitted):
        if event.input.id == "save-file-directory-input":
            if event.input.value:
                self.dir = event.input.value
            else:
                self.app.notify("Please enter a folder name.", title="Folder name empty", severity="warning")
            if event.input.value:
                self.file = Path(self.dir, event.input.value)
            else:
                self.app.notify("Please enter a filename.", title="Filename empty", severity="warning")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "save-file-save-button":
            write_vocab_file(self.file, self.json)
            self.query_one("#confirmation-label", Label).content = f"Saved as {self.file}"
            self.set_timer(2, self.dismiss)
        elif event.button.id == "save-file-dont-save-button":
            self.dismiss("don't save")
        elif event.button.id == "save-file-cancel-button":
            self.dismiss()

class EditPage(Container):
    def __init__(self, file: str|Path = ""):
        super().__init__()
        self.app.query_one("#logo", Static).display = False

        if file:
            self.json = read_vocab_file(file)
        else:
            self.json = {
                "languages": {
                    "learning": "",
                    "spoken": ""
                },
                "words": {

                }
            }

    def compose(self) -> ComposeResult:
        yield VocabularyRow(id="languages-row", delete_button=False, placeholders=("Language", "Translation language"))
        
        with VerticalScroll(id="table"):
            yield VocabularyRow()

        with Horizontal():
            yield Button(label="Add row", id="add", flat=True)
            yield Button(label="Close", id="close", flat=True)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "add":
            self.query_one("#table").mount(VocabularyRow())
        elif event.button.id == "close":
            self.app.push_screen(
                SaveFileScreen(self.json),
                callback=self.handle_save_command
            )

    def on_input_submitted(self, event: Input.Submitted):
        for row in self.query(VocabularyRow):
            word = row.query_one(".word", Input)
            translation = row.query_one(".translation")

    def handle_save_command(self, result: str | None):
        pass

    def update_json(self):
        words = []
        translations = []

        languages_row = self.query_one("#languages_row", VocabularyRow)
        learning = languages_row.query_one(".word", Input).value
        spoken = languages_row.query_one(".translation", Input).value

        if learning and spoken:
            for row in self.query(VocabularyRow):
                if not row.id == "languages_row":
                    words.append(
                        row.query_one(".word", Input).value
                    )
                    translations.append(
                        row.query_one(".translation", Input).value
                    )

            for i, (word, translation) in enumerate(zip(words, translations)):
                if not word:
                    del words[i]
                elif not translation:
                    del translations[i]

            if words and translations:
                self.json["languages"]["learning"] = str(learning)
                self.json["languages"]["spoken"] = str(spoken)

                for word, translation in zip(words, translations):
                    if word and translation:
                        self.json["words"][str(word)] = str(translation)
                    else:
                        self.app.notify("Every word must have a translation. Skipping.", title="Skipping word", severity="information")
            else:
                self.app.notify("Please enter words and translations.", title="Unable to prepare vocab data", severity="warning")