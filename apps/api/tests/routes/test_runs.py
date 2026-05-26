"""Integration tests for calibration run routes."""

import uuid

import pytest

from ite_api.auth.passwords import hash_password
from ite_api.db.models import User


@pytest.fixture()
def engineer(db_session):
    u = User(
        email="eng@example.com",
        full_name="Engineer",
        password_hash=hash_password("strongpassword12"),
        role="engineer",
    )
    db_session.add(u)
    db_session.commit()
    return u


@pytest.fixture()
def authed_client(client, engineer, tmp_path, monkeypatch):
    monkeypatch.setenv("ITE_DATA_DIR", str(tmp_path))
    resp = client.post("/api/auth/login", json={"email": "eng@example.com", "password": "strongpassword12"})
    assert resp.status_code == 204
    return client


_RUN_BODY = {
    "batch_name": "Test Batch 2026-04",
    "testing_start": "2026-04-14T09:00:00Z",
    "testing_end": "2026-04-14T17:00:00Z",
    "certificate_date": "2026-04-15",
    "threshold_c": 0.5,
    "setpoints": [
        {"target_c": -40.0, "start_at": "1900-01-01T00:00:00Z", "end_at": "2999-12-31T23:59:00Z"},
        {"target_c": 5.0,   "start_at": "1900-01-01T00:00:00Z", "end_at": "2999-12-31T23:59:00Z"},
        {"target_c": 40.0,  "start_at": "1900-01-01T00:00:00Z", "end_at": "2999-12-31T23:59:00Z"},
    ],
    "start_cert_no": "0000001800",
    "cert_width": 10,
    "test_date_jp": "2026年4月14日",
    "doc_date_jp": "2026年4月15日",
}


def test_create_and_list_runs(authed_client):
    resp = authed_client.post("/api/runs", json=_RUN_BODY)
    assert resp.status_code == 201
    run = resp.json()
    assert run["status"] == "draft"
    assert run["batch_name"] == "Test Batch 2026-04"

    lst = authed_client.get("/api/runs")
    assert lst.status_code == 200
    assert any(r["id"] == run["id"] for r in lst.json())


def test_get_run(authed_client):
    run_id = authed_client.post("/api/runs", json=_RUN_BODY).json()["id"]
    resp = authed_client.get(f"/api/runs/{run_id}")
    assert resp.status_code == 200
    assert resp.json()["id"] == run_id


def test_get_run_not_found(authed_client):
    resp = authed_client.get(f"/api/runs/{uuid.uuid4()}")
    assert resp.status_code == 404


def test_upload_reference_file(authed_client):
    run_id = authed_client.post("/api/runs", json=_RUN_BODY).json()["id"]
    csv_content = b"DateTime,Temp\n2026-04-14 10:00:00,-39.9\n"
    resp = authed_client.post(
        f"/api/runs/{run_id}/references",
        files={"file": ("ref.csv", csv_content, "text/csv")},
    )
    assert resp.status_code == 201
    data = resp.json()
    assert "file_id" in data
    assert len(data["sha256"]) == 64


def test_upload_calibration_file(authed_client):
    from pathlib import Path
    wb_path = Path(__file__).parent.parent / "fixtures" / "calibration" / "workbook.xlsx"
    if not wb_path.exists():
        pytest.skip("workbook.xlsx fixture not found")
    run_id = authed_client.post("/api/runs", json=_RUN_BODY).json()["id"]
    with open(wb_path, "rb") as f:
        resp = authed_client.post(
            f"/api/runs/{run_id}/calibration",
            files={"file": ("workbook.xlsx", f, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")},
        )
    assert resp.status_code == 201
    data = resp.json()
    assert len(data["sheet_names"]) > 0


def test_process_requires_files(authed_client):
    run_id = authed_client.post("/api/runs", json=_RUN_BODY).json()["id"]
    resp = authed_client.post(f"/api/runs/{run_id}/process")
    assert resp.status_code == 422


def test_get_status(authed_client):
    run_id = authed_client.post("/api/runs", json=_RUN_BODY).json()["id"]
    resp = authed_client.get(f"/api/runs/{run_id}/status")
    assert resp.status_code == 200
    assert resp.json()["status"] == "draft"


def test_delete_run_requires_admin(authed_client):
    run_id = authed_client.post("/api/runs", json=_RUN_BODY).json()["id"]
    resp = authed_client.delete(f"/api/runs/{run_id}")
    assert resp.status_code == 403
