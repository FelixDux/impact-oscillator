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

        # self._axes.set_ybound(upper=0)

        self._axes.set_title(str(parameters))

    @property
    def axes(self) -> Axes:
        return self._axes

    def add_sequence(self, states: List[StateOfMotion]) -> None:
        # Marshall states
        t_values = [state.t for state in states]
        x_values = [state.x for state in states]

        self._axes.plot(t_values, x_values)


if __name__ == "__main__":
    from imposcpy.imposc.motion import MotionBetweenImpacts, ImpactPoint

    params = SystemParameters(omega=2.8, r=0.8, sigma=0)

    start_point = ImpactPoint(phi=1, v=1)

    fig = py.figure()

    axes = AxesForTimeSeries(fig.add_subplot(), params)

    transient = MotionBetweenImpacts(params, start_point)

    [transient.iterate() for i in range(1000)]

    motion = MotionBetweenImpacts(params, transient.next_impact(), recording=True)
    
    [motion.iterate() for i in range(5)]

    axes.add_sequence(motion.steps)

    py.show()