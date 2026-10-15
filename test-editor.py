from textual.app import App, ComposeResult
from textual.containers import Horizontal, VerticalScroll
from textual.widgets import Button, Input


class VocabularyRow(Horizontal):
    def __init__(self, word: str = "", translation: str = ""):
        super().__init__()
        self.word = word
        self.translation = translation

    def compose(self) -> ComposeResult:
        yield Input(self.word, classes="word")
        yield Input(self.translation, classes="translation")
        yield Button("×", classes="delete", variant="error")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.has_class("delete"):
            self.remove()


class VocabularyEditor(App):
    CSS = """
    #table {
        height: 1fr;
        border: solid $primary;
    }

    VocabularyRow {
        layout: horizontal;
        width: 100%;
        height: 3;
    }

    VocabularyRow Input {
        width: 1fr;
    }

    VocabularyRow .delete {
        width: 5;
        min-width: 5;
    }

    #add {
        margin: 1;
    }
    """

    def compose(self) -> ComposeResult:
        with VerticalScroll(id="table"):
            yield VocabularyRow("hello", "bonjour")
            yield VocabularyRow("goodbye", "au revoir")
            yield VocabularyRow("thanks", "merci")

        yield Button("Add row", id="add")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "add":
            self.query_one("#table").mount(VocabularyRow())


if __name__ == "__main__":
    VocabularyEditor().run()