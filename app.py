from pathlib import Path

# Import pages from other files
from about import AboutPage
from edit_vocab_file import EditPage
from learn import LearnPage
from rich.text import Text
from textual import on
from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal
from textual.reactive import reactive
from textual.widget import Widget
from textual.widgets import Button, Header, Label, Static

filedir = Path(__file__).parent

class VocabularyPlusApp(App):
    CSS_PATH = filedir / "VocabularyPlus.tcss"
    TITLE = "Vocabulary Plus"
    BINDINGS = [
        ("q", "quit", "Quit")
    ]

    NAV_PAGES = {
        "learn": (LearnPage, "Learn"),
        "edit": (EditPage, "Edit"),
        "about": (AboutPage, "About")
    }

    display_logo = reactive(bool, init=False, recompose=True)
    current_page = reactive(str, init=False)
    previous_page = "learn"

    def compose(self) -> ComposeResult:
        yield Header()

        yield Static(Text.from_ansi(open(filedir / "icons" / "text_icon.ans").read().strip()), id="logo")

        yield Container(
            Label(""),
            id="content"
        )

        with Horizontal(id="navbar"):
            for nav_id in self.NAV_PAGES.keys():
                yield Button(label=self.NAV_PAGES[nav_id][1], id=nav_id)
    
    def watch_display_logo(self, display_logo: bool):
        self.query_one("#logo", Static).display = display_logo

    def watch_current_page(self, current_page: str) -> None:
        # Remove the selected class from all navigation buttons
        for button_id in self.NAV_PAGES:
            self.query_one(f"#{button_id}", Button).remove_class("selected")

        # Highlight the current page if it has a navigation button
        button = self.query_one_optional(f"#{current_page}", Button)
        if button is not None:
            button.add_class("selected")

    def get_key_of_value(self, value, dictionary: dict):
        for key, values in dictionary.items():
            if value in values:
                return key
        
        return None

    def show_page(self, page: type[Widget]) -> None:
        page_key = self.get_key_of_value(page, self.NAV_PAGES)
        if page_key is not None:
            self.current_page = page_key

        content = self.query_one("#content", Container)

        # Remove current page
        content.remove_children()

        # Show the new page
        content.mount(page())

    def on_mount(self):
        #self.show_page(self.NAV_PAGES["edit"][0])
        self.show_page(self.NAV_PAGES["learn"][0])
    
    @on(Button.Pressed)
    def on_nav_button(self, event: Button.Pressed) -> None:
        if event.button.id:
            page = self.NAV_PAGES.get(event.button.id)
        else:
            page = None

        if page is not None:
            event.button.toggle_class("selected")
            self.show_page(page[0])

if __name__ == "__main__":
    VocabularyPlusApp().run()