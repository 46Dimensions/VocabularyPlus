import json
import random
from datetime import datetime
from pathlib import Path
from typing import NamedTuple, cast

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, ScrollableContainer
from textual.reactive import reactive
from textual.screen import ModalScreen
from textual.widget import Widget
from textual.widgets import Button, Input, Label

from filepicker import FilePicker
from vocab_io import read_vocab_file, write_vocab_file

filedir = Path(__file__).parent

class LearnPage(ScrollableContainer):
    CSS = filedir / "VocabularyPlus.tcss"
    selected_vocab_file: Path = Path()
    quiz_data: dict = {}

    def compose(self) -> ComposeResult:
        yield Container(Label(""), id="content")

    def show_page(self, page: type[Widget]) -> None:
        content = self.query_one("#content", Container)

        # Remove current page
        content.remove_children()

        # Show the new page
        content.mount(page())

    def on_mount(self):
        self.show_page(StartPage)

class QuestionPage(Container):
    CSS = filedir / "VocabularyPlus.tcss"
    quiz_data = {
        "correct": 0,
        "incorrect": 0,
        "not answered": 0
    }
    correct_incorrect = reactive(str)

    class QuestionInfo(NamedTuple):
        question: str
        answer: str

    def compose(self) -> ComposeResult:
        app = cast(LearnPage, self.app)
        self.vocab_filename = app.selected_vocab_file

        self.question_number = 1
        yield Label(f"[yellow]Question {self.question_number}[/yellow]", classes="title", id="question-header")

        self.vocab_dict = read_vocab_file(self.vocab_filename)
        self.question_data = self.get_question(self.vocab_dict)
        yield Label(self.question_data.question, id="question-label")

        yield Input(placeholder="Enter your answer...", id="answer-input")

        self.correct_incorrect_label = Label()
        self.correct_incorrect_label.display = False
        yield self.correct_incorrect_label

        yield Button("✖ Exit", id="exit-button", flat=True)

    def watch_correct_incorrect(self, correct_incorrect: str):
        self.correct_incorrect_label.update(correct_incorrect)

    def get_question(self, vocab_dict: dict) -> QuestionInfo:
        languages: dict[str, str] = vocab_dict["languages"]
        words: dict[str, str] = vocab_dict["words"]

        word_key = random.choice(list(words.keys()))

        question_language_type = random.choice(["learning", "spoken"])
        if question_language_type == "learning":
            question_word = words[word_key] # This would be in the "learning" language
            answer_word = word_key
        else:
            question_word = word_key
            answer_word = words[word_key]

        question_language = languages[question_language_type]

        if question_language_type == "spoken":
            question_body = f"What does '{question_word}' mean in {question_language}?"
        else:
            question_body = f"What is '{question_word}' in {question_language}?"

        return self.QuestionInfo(question=question_body, answer=answer_word)

    def new_question(self):
        self.vocab_dict = read_vocab_file(self.vocab_filename)
        self.question_data = self.get_question(self.vocab_dict)
        self.question_number += 1

        question_header = self.query_one("#question-header", Label)
        question_label = self.query_one("#question-label", Label)
        answer_input = self.query_one("#answer-input", Input)

        question_header.update(f"[yellow]Question {self.question_number}[/yellow]")
        question_label.update(self.question_data.question)
        answer_input.clear()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if event.input.id == "answer-input":
            user_input = event.value
            answer = self.question_data.answer
            self.correct_incorrect_label.display = True

            if user_input.lower() == answer.lower():
                self.correct_incorrect = "[lightgreen]Correct.[/lightgreen]"
                self.quiz_data["correct"] += 1
            else:
                self.correct_incorrect = f"[red]Incorrect. Correct answer: {answer}[/red]"
                if user_input != "":
                    self.quiz_data["incorrect"] += 1
                else:
                    self.quiz_data["not answered"] += 1

            def reset():
                self.correct_incorrect_label.display = False
                self.new_question()

            self.set_timer(2, reset)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "exit-button":
            app = cast(LearnPage, self.app)
            app.quiz_data = self.quiz_data
            app.show_page(SummaryPage)

class StartPage(Container):
    BINDINGS = [
        ("ctrl o", "open_file", "Open file")
    ]
    def compose(self) -> ComposeResult:
        yield Label("No vocabulary file opened", classes="title")
        yield Button("Open file", id="open-quiz-file", flat=True)

    def action_open_file(self):
        self.app.push_screen(FilePicker(), self.file_selected)

    def on_button_pressed(self, event: Button.Pressed):
        self.action_open_file()

    def file_selected(self, path: Path | None):
        if path is not None:
            app = cast(LearnPage, self.app)
            app.selected_vocab_file = path
            app.show_page(QuestionPage)

class SummaryPage(Container):
    CSS = filedir / "VocabularyPlus.tcss"
    quiz_data = {}

    def compose(self) -> ComposeResult:
        yield Label("Quiz Summary", classes="title")

        app = cast(LearnPage, self.app)
        self.quiz_data = app.quiz_data
        correct, incorrect, not_answered = (self.quiz_data["correct"], self.quiz_data["incorrect"], self.quiz_data["not answered"])
        total = sum([correct, incorrect, not_answered])

        yield Label(f"Questions attempted: {total}")
        yield Label(f"[lightgreen]Correct: {correct}[/lightgreen]")
        yield Label(f"[red]Incorrect: {incorrect}[/red]")
        yield Label(f"[yellow]Not answered: {not_answered}[/yellow]")

        percentage_label = Label()
        yield percentage_label

        if total > 0:
            percentage_label.update(f"[cyan]Percentage: {correct / total * 100:.0f}%[/cyan]")
        else:
            percentage_label.visible = False

        with Horizontal():
            yield Button("💾 Save quiz", flat=True, id="save-quiz")
            yield Button("✖ Exit", flat=True, id="exit-summary")

    def write_json(self, filename: str | Path, dictionary: dict):
        try:
            with open(filename, "w") as file:
                file.seek(0)
                json.dump(dictionary, file)
        except FileNotFoundError:
            self.notify("That file does not exist.",
                        title="File not found"
                    )

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "save-quiz":
            self.app.push_screen(SaveQuizPage())
        elif event.button.id == "exit-summary":
            app = cast(LearnPage, self.app)
            app.show_page(StartPage)

class SaveQuizPage(ModalScreen):
    CSS_PATH = filedir / "VocabularyPlus.tcss"
    BINDINGS = [
        ("escape", "exit", "Close")
    ]

    def compose(self) -> ComposeResult:
        with ScrollableContainer(id="save-quiz-screen"):
            yield Label("Save Quiz", classes="title")

            yield Label("Enter name of quiz:")

            yield Input(id="quiz-name-input")

            self.confirmation_label = Label(id="success")
            self.confirmation_label.display = False
            yield self.confirmation_label

    def on_mount(self):
        app = cast(LearnPage, self.app)

        filename = str(app.selected_vocab_file.name)

        if filename.endswith(".json"):
            filename = filename.removesuffix(".json")
        elif filename.endswith(".vocab"):
            filename = filename.removesuffix(".vocab")

        self.quiz_data = app.quiz_data
        self.time = datetime.now()

        self.query_one("#quiz-name-input", Input).value = f"{filename}: {self.time.strftime("%H:%M:%S %d %b %Y")}"

        save_quiz_screen = self.query_one("#save-quiz-screen", ScrollableContainer)
        save_quiz_screen.border_title = "Save Quiz"
        save_quiz_screen.border_subtitle = "Press esc to close"

    def save_quiz(self, path: Path):
        # Add version and time data
        self.quiz_data["version"] = "2.0.0 Beta 2" # The Vocabulary Plus version that made it
        self.quiz_data["time"] = self.time.strftime("%H:%M:%S %d %b %Y")

        write_vocab_file(path, self.quiz_data)

        self.confirmation_label.update(f"[green]Saved as {path}[/green]")
        self.confirmation_label.display = True

    def on_input_submitted(self, event: Input.Submitted):
        quiz_dir = filedir / "quizzes"
        quiz_dir.mkdir(parents=True, exist_ok=True)

        quiz_file_path = quiz_dir / f"{event.value}.quiz"
        
        self.save_quiz(quiz_file_path)

        self.set_timer(2, self.action_exit)

    def action_exit(self):
        self.dismiss()