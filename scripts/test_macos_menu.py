"""Check native-menu argument handling without opening macOS dialogs."""
import io
from pathlib import Path
import runpy
import subprocess
import unittest
from unittest.mock import patch


class MenuTest(unittest.TestCase):
    def run_menu(self, text, result):
        output = io.StringIO()
        errors = io.StringIO()
        with (
            patch("sys.argv", ["qute-menu", "-p", 'Select "account"', "-lines", "0"]),
            patch("sys.stdin", io.StringIO(text)),
            patch("sys.stdout", output),
            patch("sys.stderr", errors),
            patch("subprocess.run", return_value=result) as run,
        ):
            try:
                runpy.run_path(str(Path(__file__).with_name("macos-menu.py")))
            except SystemExit as error:
                return run.call_args, output.getvalue(), errors.getvalue(), error.code
        return run.call_args, output.getvalue(), errors.getvalue(), 0

    def test_entries_are_arguments_and_selection_is_preserved(self):
        call, output, _, status = self.run_menu(
            'normal\nquote " and backslash \\\n',
            subprocess.CompletedProcess([], 0, 'quote " and backslash \\\n', ""),
        )
        self.assertEqual(call.args[0][3:], ["--", 'Select "account"', "normal", 'quote " and backslash \\'])
        self.assertEqual(output, 'quote " and backslash \\\n')
        self.assertEqual(status, 0)

    def test_empty_input_uses_text_prompt_and_cancel_returns_empty(self):
        call, output, _, status = self.run_menu("", subprocess.CompletedProcess([], 0, "", ""))
        self.assertEqual(call.args[0][3:], ["--", 'Select "account"'])
        self.assertEqual((output, status), ("", 0))

    def test_unexpected_errors_are_reported(self):
        _, output, errors, status = self.run_menu("", subprocess.CompletedProcess([], 2, "", "failed"))
        self.assertEqual((output, errors, status), ("", "failed", 2))


if __name__ == "__main__":
    unittest.main()
