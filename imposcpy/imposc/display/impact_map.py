import matplotlib.pyplot as py
from matplotlib.axes import Axes
from math import pi
from typing import List

from imposcpy.imposc.constants import SMALL_PHI
from imposcpy.imposc.motion import ImpactPoint
from imposcpy.imposc.parameters import SystemParameters
    

class AxesForImpactMap:
    def __init__(self, axes: Axes, parameters: SystemParameters):
        self._axes = axes

        self._axes.set_xlabel(SMALL_PHI)
        self._axes.set_ylabel('v')

        self._axes.set_ybound(lower=0)
        self._axes.set_xbound(lower=0, upper=2.0 * pi / parameters.omega)

        self._axes.set_title(str(parameters))

    @property
    def axes(self) -> Axes:
        return self._axes

    def add_sequence(self, points: List[ImpactPoint]) -> None:
        # Marshall points
        phi_values = [point.phi for point in points]
        v_values = [point.v for point in points]

        self._axes.scatter(phi_values, v_values, marker='.', s=1, label=str(points[0]))


if __name__ == "__main__":
    from imposcpy.imposc.motion import MotionBetweenImpacts
    from imposcpy.imposc.motion import MotionBetweenImpacts, ImpactPoint
    from imposcpy.imposc.periodic import OneNParams

    params = SystemParameters(omega=2, r=0.8, sigma=0.1)
    one_n_params = OneNParams(parameters=params, n=1)

    v = [v for v in one_n_params.velocities(params.sigma) if v > 0][0]

    start_point = one_n_params.point_for_velocity(v, params.sigma)

    fig = py.figure()

    axes = AxesForImpactMap(fig.add_subplot(), params)

    motion = MotionBetweenImpacts(params, start_point)

    # [motion.iterate() for i in range(100)]

    points = [motion.iterate() for i in range(1000)]

    axes.add_sequence(points)

    axes.axes.legend()

    py.show()

    


