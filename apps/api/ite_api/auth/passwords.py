from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError

# Spec §5: argon2id, t=3, m=64MB, p=4
_hasher = PasswordHasher(time_cost=3, memory_cost=64 * 1024, parallelism=4)


def hash_password(plaintext: str) -> str:
    return _hasher.hash(plaintext)


def verify_password(plaintext: str, hashed: str) -> bool:
    try:
        return _hasher.verify(hashed, plaintext)
    except (VerifyMismatchError, InvalidHashError, Exception):
        return False
