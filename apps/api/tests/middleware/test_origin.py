def test_post_without_origin_header_is_rejected(client):
    r = client.post(
        "/api/auth/login",
        json={"email": "a@b.co", "password": "x" * 20},
        headers={"Origin": ""},
    )
    assert r.status_code == 400


def test_post_with_allowed_origin_passes(client):
    r = client.post(
        "/api/auth/login",
        json={"email": "a@b.co", "password": "x" * 20},
        headers={"Origin": "http://localhost"},
    )
    # 401 (bad creds) means middleware let it through
    assert r.status_code in (401, 429)


def test_post_with_disallowed_origin_is_rejected(client):
    r = client.post(
        "/api/auth/login",
        json={"email": "a@b.co", "password": "x" * 20},
        headers={"Origin": "http://evil.example.com"},
    )
    assert r.status_code == 400


def test_get_does_not_require_origin(client):
    # Strip Origin from the default headers for this single call.
    r = client.get("/api/health", headers={"Origin": ""})
    assert r.status_code == 200
