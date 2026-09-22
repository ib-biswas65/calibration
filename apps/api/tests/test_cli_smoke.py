"""Real subprocess-level smoke test for the CLI.

This intentionally does NOT use typer.testing.CliRunner, which invokes the
click/typer help-rendering code in-process in a way that does not exercise
the actual argv/console entry point path. A click/typer version mismatch
(e.g. click 8.2+ removing the `ctx` default from Parameter.make_metavar,
which older typer releases still call without it) can crash real CLI
invocations while CliRunner-based tests stay green. Shelling out here
catches that class of bug.
"""

import subprocess
import sys


def test_cli_help_runs_without_crashing():
    result = subprocess.run(
        [sys.executable, "-m", "ite_api.cli", "--help"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert result.returncode == 0, result.stderr
    assert "create-admin" in result.stdout
    assert "run-calibration" in result.stdout


def test_cli_subcommand_help_runs_without_crashing():
    result = subprocess.run(
        [sys.executable, "-m", "ite_api.cli", "create-admin", "--help"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert result.returncode == 0, result.stderr
