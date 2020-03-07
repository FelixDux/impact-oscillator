from math import cos, sin, pi
from dataclasses import dataclass
from typing import List

from imposcpy.imposc.parameters import SystemParameters

def phi(t: float, omega: float) -> float:
    """
    For a given time `t` returns the phase relative to the forcing period 2 pi /`omega`
    """
    if omega == 0:
        return t
    else:
        return t % 2.0 * pi / omega

@dataclass
class ImpactPoint:
    """
    A point on the impact surface
    """
    phi: float
    v: float


@dataclass
class StateOfMotion:
    """ State and phase variables for the motion between impacts """
    x: float  # displacement
    v: float  # velocity = dx/dt
    t: float  # time

    def point_from_state(self, omega: float) -> ImpactPoint:
        return ImpactPoint(phi=phi(self.t, omega), v=self.v)


class MotionBetweenImpacts:
    """ Coefficients and methods for time evolution of the system from one impact to the next """

    def __init__(self, parameters: SystemParameters, point: ImpactPoint, recording = False, step_size = 0.01, limit = 0.000001):
        self._parameters = parameters
        self._gamma = parameters.gamma()
        self._point: ImpactPoint = None
        self._cos_coeff = 0.0
        self._sin_coeff = 0.0
        self._steps = []
        self._recording = recording
        self._step_size = step_size
        self._limit = limit

        self.set_impact(point)

    def set_impact(self, point: ImpactPoint) -> None:
        self._point = point
        self._cos_coeff = self._parameters.sigma - self._gamma * cos(self._parameters.omega * point.phi) 
        self._sin_coeff = -self._parameters.r * point.v + self._parameters.omega * self._gamma * sin(self._parameters.omega * point.phi)

    @property
    def recording(self) -> bool:
        return self._recording

    @recording.setter
    def recording(self, value: bool):
        if value != self._recording:
            self._recording = value
            self._steps.clear()

    @property
    def gamma(self) -> float:
        """ the coefficient of the forcing term of the displacement """
        return self._gamma

    @property
    def cos_coeff(self) -> float:
        """ the coefficient of the cosine term of the displacement """
        return self._cos_coeff

    @property
    def sin_coeff(self) -> float:
        """ the coefficient of the sine term of the displacement """
        return self._sin_coeff

    @property
    def steps(self) -> List[StateOfMotion]:
        return self._steps

    def motion_at_time(self, t: float) -> StateOfMotion:
        lamda = t - self._point.phi
        sin_lamda = sin(lamda)
        cos_lamda = cos(lamda)

        return StateOfMotion(t=t,
            x=self._cos_coeff * cos_lamda + self._sin_coeff * sin_lamda + self._gamma * cos(self._parameters.omega * t),
            v=self._sin_coeff * cos_lamda - self._cos_coeff * sin_lamda - self._parameters.omega * self._gamma * 
            sin(self._parameters.omega * t))

    def next_impact(self) -> ImpactPoint:

        t = self._point.phi

        penetrating = False

        step_size = self._step_size

        while abs(step_size) > self._limit:
            t += step_size

            state = self.motion_at_time(t)

            if state.x > self._parameters.sigma:
                if not penetrating:
                    step_size *= -0.5

                penetrating = True

            else:
                if penetrating:
                    step_size *= -0.5

                penetrating = False

                self._record_state(state)

        return state.point_from_state(self._parameters.omega)

    def iterate(self) -> ImpactPoint:
        next_point = self.next_impact()

        self.set_impact(next_point)

        return next_point

    def _record_state(self, state: StateOfMotion):

        if self.recording:
            self._steps.append(state)
