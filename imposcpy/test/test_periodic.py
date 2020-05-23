import pytest

from imposcpy.imposc.periodic import OneNParams
from imposcpy.imposc.parameters import SystemParameters


@pytest.mark.parametrize(("n", "params", "expected"), ([
    (1, SystemParameters(omega=2, r=0.8, sigma=0), True),
    (1, SystemParameters(omega=2, r=0.8, sigma=0.01), True),
    (1, SystemParameters(omega=2, r=0.8, sigma=-0.33), True),
    (1, SystemParameters(omega=2, r=0.8, sigma=-0.33333), False)]))
def test_physical(n, params, expected):
    one_n_params = OneNParams(parameters=params, n=n)

    velocities = [v for v in one_n_params.velocities(params.sigma) if v > 0]

    for v in velocities:
        assert one_n_params.is_physical(v, params.sigma) == expected
