# oterm themed like the rest of the Sway popups (fuzzel/mako): black, square,
# #3584E4 selection, and no "oterm - the terminal LLM client." header bar.
# Wraps the pipx install instead of patching it, so `pipx upgrade` keeps this.
# Run with the oterm venv's python (see sway/scripts/ai-chat).
from textual.theme import Theme

from oterm.log import suppress_logging

suppress_logging()

from oterm.app.oterm import app  # noqa: E402

app.register_theme(
    Theme(
        name="sway",
        primary="#3584E4",
        secondary="#99C1F1",
        accent="#F6D32D",
        foreground="#B8B8B8",
        background="#000000",
        surface="#000000",
        panel="#111111",
        success="#33D17A",
        warning="#F6D32D",
        error="#E01B24",
        dark=True,
    )
)
app.CSS = "Header { display: none; }"
app.run()
