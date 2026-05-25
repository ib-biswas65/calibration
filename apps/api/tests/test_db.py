from ite_api.db.base import Base


def test_base_metadata_is_empty_for_now():
    # Slice 0: no models registered yet
    assert Base.metadata.tables == {}
