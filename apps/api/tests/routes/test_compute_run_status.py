"""Unit tests for _compute_run_status — pure, no DB needed.

Extracted from _do_process during a code-quality pass: the run-status decision
used to be two hand-threaded booleans (any_valid/any_invalid) set at three
different branch points in the processing loop. This makes the decision a
single, independently testable function derived from the actual verdicts.
"""

from ite_api.routes.runs import _compute_run_status


def test_all_valid_results_is_complete():
    status, reason = _compute_run_status(["pass", "pass", "fail"])
    assert status == "complete"
    assert reason is None


def test_mix_of_valid_and_invalid_is_partial():
    status, reason = _compute_run_status(["pass", "invalid", "fail"])
    assert status == "partial"
    assert reason is None


def test_all_invalid_is_failed_with_a_reason():
    status, reason = _compute_run_status(["invalid", "invalid"])
    assert status == "failed"
    assert reason is not None
    assert "failed validation" in reason["message"]


def test_no_results_is_complete():
    """An empty sheet list (e.g. a workbook with zero sheets) has nothing to be
    invalid — falls through to complete rather than failed, matching the
    pre-refactor behavior (any_invalid stays False either way)."""
    status, reason = _compute_run_status([])
    assert status == "complete"
    assert reason is None
