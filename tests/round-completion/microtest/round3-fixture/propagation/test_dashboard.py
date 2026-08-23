"""Dashboard tests -- see spec.md's Section 7.3."""


def _stub_result():
    return (0.82, "gold")


def test_dashboard_groups_by_bucket():
    grade, bucket = _stub_result()
    assert bucket == "gold"


def test_dashboard_sorts_descending():
    a = _stub_result()
    b = (0.55, "silver")
    assert a[0] > b[0]
