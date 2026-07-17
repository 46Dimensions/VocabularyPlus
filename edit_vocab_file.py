from textual.app import ComposeResult
from textual.containers import Container
from textual.widgets import Markdown

MARKDOWN = """
## Under development
The Vocabulary file editor is under development.

It will be available in future [releases](https://github.com/46Dimensions/VocabularyPlus/releases).
You can see current progress on the [**`2.0.0`**](https://github.com/46Dimensions/VocabularyPlus/tree/2.0.0) branch.
"""

class EditPage(Container):
    def compose(self) -> ComposeResult:
        yield Markdown(MARKDOWN)