import matplotlib.pyplot as py
from matplotlib.axes import Axes
from typing import List

from imposcpy.imposc.parameters import SystemParameters
from imposcpy.imposc.motion import StateOfMotion
    

class AxesForTimeSeries:
    def __init__(self, axes: Axes, parameters: SystemParameters):
        self._axes = axes

        self._axes.set_xlabel('t')
        self._axes.set_ylabel('x')

        self._axes.set_title(str(parameters))

        self._parameters = parameters

    @property
    def axes(self) -> Axes:
        return self._axes

    def add_sequence(self, states: List[StateOfMotion]) -> None:
        # Marshall states
        t_values = [state.t for state in states]
        x_values = [state.x for state in states]

        self._axes.plot(t_values, x_values, label=states[0].point_from_state(self._parameters.omega))

        self._axes.set_ybound(upper=self._parameters.sigma)


if __name__ == "__main__":
    from imposcpy.imposc.motion import MotionBetweenImpacts, ImpactPoint
    from imposcpy.imposc.periodic import OneNParams

    params = SystemParameters(omega=2, r=0.8, sigma=0.1)
    one_n_params = OneNParams(parameters=params, n=1)

    v = [v for v in one_n_params.velocities(params.sigma) if v > 0][0]

    start_point = one_n_params.point_for_velocity(v, params.sigma)

    # start_point = ImpactPoint(phi=1, v=1)

    fig = py.figure()

    axes = AxesForTimeSeries(fig.add_subplot(), params)
    #
    # transient = MotionBetweenImpacts(params, start_point)
    #
    # [transient.iterate() for i in range(1000)]
    #
    # motion = MotionBetweenImpacts(params, transient.next_impact(), recording=True)

    motion = MotionBetweenImpacts(params, start_point, recording=True)

    [motion.iterate() for i in range(5)]

    axes.add_sequence(motion.steps)

    axes.axes.legend()

    py.show()