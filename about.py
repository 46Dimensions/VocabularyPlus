from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Container
from textual.widgets import TextArea

filedir = Path(__file__).parent

class AboutPage(Container):
    ABOUT_FILE = filedir / "about.txt"

    def compose(self) -> ComposeResult:
        text = self.read_about_file()
        yield TextArea(text, read_only=True)

    def read_about_file(self) -> str:
        with open(self.ABOUT_FILE, "r") as f:
            contents = f.read().strip()
            return contents