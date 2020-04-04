import matplotlib.pyplot as py
from matplotlib.axes import Axes
from typing import List

from imposcpy.imposc.parameters import SystemParameters
from imposcpy.imposc.periodic import OneNParams, curves_for_fixed_omega
from imposcpy.imposc.constants import SMALL_SIGMA
    

class AxesForOneN:
    def __init__(self, axes: Axes):
        self._axes = axes

        self._axes.set_xlabel(SMALL_SIGMA)
        self._axes.set_ylabel('V')
        self._axes.set_ybound(lower=0)

        self._axes.set_title(f"{SMALL_SIGMA} response curves for (1, n) orbits")

    @property
    def axes(self) -> Axes:
        return self._axes

    def add_sequence(self, sigmas: List[float], velocities: List[float], label="") -> None:

        self._axes.plot(sigmas, velocities, label=label)


if __name__ == "__main__":
    fig = py.figure()

    axes = AxesForOneN(fig.add_subplot())

    axes.add_sequence(*curves_for_fixed_omega(1, SystemParameters(omega=1.8, r=0.8, sigma=0)))

    axes.add_sequence(*curves_for_fixed_omega(1, SystemParameters(omega=2, r=0.8, sigma=0)))

    axes.add_sequence(*curves_for_fixed_omega(1, SystemParameters(omega=2.2, r=0.8, sigma=0)))
    
    axes.axes.legend()

    py.show()