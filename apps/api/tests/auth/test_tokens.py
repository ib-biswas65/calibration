import pytest

from ite_api.auth.tokens import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_refresh_token,
)


def test_access_token_round_trip(monkeypatch):
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    token = create_access_token(user_id="abc-123", role="admin")
    claims = decode_access_token(token)
    assert claims["sub"] == "abc-123"
    assert claims["role"] == "admin"


def test_access_token_rejects_wrong_secret(monkeypatch):
    monkeypatch.setenv("ITE_JWT_SECRET", "secret-one-32-bytes-of-padding-aa")
    token = create_access_token(user_id="x", role="viewer")
    monkeypatch.setenv("ITE_JWT_SECRET", "secret-two-32-bytes-of-padding-aa")
    with pytest.raises(Exception):
        decode_access_token(token)


def test_refresh_token_is_unique_and_hashable():
    a = create_refresh_token()
    b = create_refresh_token()
    assert a != b
    assert len(a) >= 32
    assert hash_refresh_token(a) == hash_refresh_token(a)
    assert hash_refresh_token(a) != hash_refresh_token(b)
    assert len(hash_refresh_token(a)) == 64  # sha256 hex
