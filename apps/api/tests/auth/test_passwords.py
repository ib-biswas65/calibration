from ite_api.auth.passwords import hash_password, verify_password


def test_hash_password_is_argon2id():
    h = hash_password("correct horse battery staple")
    assert h.startswith("$argon2id$")


def test_verify_password_round_trip():
    h = hash_password("hunter2-very-long-password")
    assert verify_password("hunter2-very-long-password", h) is True
    assert verify_password("wrong", h) is False


def test_hashes_are_unique_per_call():
    a = hash_password("same-password-each-time-please")
    b = hash_password("same-password-each-time-please")
    assert a != b


def test_verify_handles_invalid_hash_gracefully():
    assert verify_password("anything", "not-a-real-hash") is False
