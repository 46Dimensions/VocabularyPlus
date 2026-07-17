import os
from pathlib import Path

from textual.app import ComposeResult
from textual.containers import ScrollableContainer
from textual.reactive import reactive
from textual.screen import ModalScreen
from textual.widgets import Input, Label, OptionList

filedir = Path(__file__).parent

class FilePicker(ModalScreen):
    CSS_PATH = filedir / "VocabularyPlus.tcss"
    BINDINGS = [
        ("escape", "exit", "Close")
    ]
    vocab_dir = reactive(filedir / "vocab", init=False)

    def compose(self) -> ComposeResult:
        with ScrollableContainer(classes="modalscreen-contents", id="filepicker"):
            yield Label("Choose a vocabulary file", classes="title")

            yield Label(f"Directory: {self.vocab_dir}", id="vocab-dir-label")
            yield Input(placeholder="Change...", id="vocab-dir-input")

            files = self.get_files(self.vocab_dir)

            if not files:
                self.notify("No valid vocabulary files found.",
                            title="No files",
                            severity="warning",
                            timeout=1.0
                )

            yield OptionList(*files.keys(), id="filepicker-list")
            self.selected_item_label = Label("")
            yield self.selected_item_label

    def watch_vocab_dir(self, vocab_dir):
        self.query_one("#vocab-dir-label", Label).update(f"Directory: {vocab_dir}")

    def on_mount(self) -> None:
        filepicker_widget = self.query_one("#filepicker", ScrollableContainer)
        filepicker_widget.border_title = "Choose a vocabulary file"
        filepicker_widget.border_subtitle = "Press esc to close"

    def action_exit(self):
        self.dismiss(None)

    def get_files(self, directory) -> dict[str, str]:
        def remove_extension(filename: str|Path) -> str:
            path = Path(filename)
            if path.suffix.lower() in {".json", ".vocab"}:
                return path.with_suffix("").name
            return path.name

        files_in_dir: list[str] = os.listdir(directory)
        valid_files = {}

        for file in files_in_dir:
            file = Path(file)
            if file.suffix.lower() in (".json", ".vocab"):
                extensionless_file = remove_extension(file.name)
                valid_files[extensionless_file] = os.path.join(directory, file.name)

        return valid_files

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        valid_files = self.get_files(self.vocab_dir)
        filename_with_extension = valid_files[str(event.option.prompt)]
        full_path = Path(self.vocab_dir) / filename_with_extension

        self.dismiss(full_path)

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if os.path.exists(event.value.strip()) and os.path.isdir(event.value.strip()):
            self.vocab_dir = event.value.strip()
            option_list = self.query_one(OptionList)

            files = self.get_files(self.vocab_dir)

            if not files:
                self.notify("No valid vocabulary files found.\nTry a different directory",
                            title="No files",
                            severity="warning"
                )

            option_list.clear_options()
            option_list.add_options(files)
            event.input.value = ""
        else:
            self.notify("That vocabulary file directory does not exist.",
                        title="Directory doesn't exist",
                        severity="error",
                        timeout=2.0
            )