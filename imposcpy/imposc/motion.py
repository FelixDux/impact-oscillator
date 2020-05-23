""" Classes and functions for computing the equations of motion between successive impacts """

from math import cos, sin, pi
from dataclasses import dataclass
from typing import List

from imposcpy.imposc.parameters import SystemParameters
from imposcpy.imposc.constants import SMALL, SMALL_PHI


def forcing_period(omega: float) -> float:
    """
    Returns the period of a forcing cycle for a given forcing frequency

    :param omega: the forcing frequency (dimensionless)
    :return: the corresponding forcing period (dimensionless)
    """
    return 2.0 * pi / omega


def phi(t: float, omega: float) -> float:
    """
    For a given (dimensionless) time `t` returns the phase relative to the forcing period 2 pi /`omega`
    """
    if omega == 0:
        return t
    else:
        return t % forcing_period(omega)


@dataclass
class ImpactPoint:
    """
    A point on the impact surface
    """
    phi: float
    v: float

    def __str__(self) -> str:
        """ A human-readable string representation """
        return f"{SMALL_PHI} = {self.phi}, v = {self.v}"

    def __repr__(self) -> str:
        """ An unambiguous string representation """
        return f"<{self.__class__.__name__}: {self.__str__()}>"


@dataclass
class StateOfMotion:
    """ State and phase variables for the motion between impacts """
    x: float  # displacement
    v: float  # velocity = dx/dt
    t: float  # time

    def point_from_state(self, omega: float) -> ImpactPoint:
        """
        Derives a point on the impact surface from the state of motion. In general this is only meaningful if the
        displacement `x` is equal to the obstacle offset `sigma` but the mathematical construction only relies on the
        forcing frequency `omega`.

        :param omega: the (dimensionless) forcing frequency
        :return: a point on the impact surface `x`=`sigma`
        """
        return ImpactPoint(phi=phi(self.t, omega), v=self.v)

    def __str__(self) -> str:
        """ A human-readable string representation """
        return f"x = {self.phi}, v = {self.v}, t = {self.t}"

    def __repr__(self) -> str:
        """ An unambiguous string representation """
        return f"<{self.__class__.__name__}: {self.__str__()}>"


class MotionBetweenImpacts:
    """ Coefficients and methods for time evolution of the system from one impact to the next """

    def __init__(self, parameters: SystemParameters, point: ImpactPoint, recording=False, step_size=0.01,
                 limit=0.000001):
        """

        :param parameters: a `SystemParameters` instance defining the (nondimensionalised) system
        :param point: an `ImpactPoint` instance specifying the initial conditions for the motion
        :param recording: if `True`, the states of motion at each intermediate time step will be recorded in the `steps`
        property
        :param step_size: the initial time step size
        :param limit: the minimum time step size, below which the bisection search for the next impact will terminate
        """
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

    def __str__(self) -> str:
        """ A human-readable string representation """
        return f"{self._parameters}, {self._point}"

    def __repr__(self) -> str:
        """ An unambiguous string representation """
        return f"<{self.__class__.__name__}: {self.__str__()}>"

    def set_impact(self, point: ImpactPoint) -> None:
        """
        Sets the initial conditions of the motion from an impact and appropriately updates the motion coefficients

        :param point: an `ImpactPoint` instance specifying the initial conditions for the motion
        :return:
        """
        self._point = point
        self._cos_coeff = self._parameters.sigma - self._gamma * cos(self._parameters.omega * point.phi)
        self._sin_coeff = -self._parameters.r * point.v + self._parameters.omega * self._gamma * sin(
            self._parameters.omega * point.phi)

    @property
    def recording(self) -> bool:
        """ If `True`, the states of motion at each intermediate time step will be recorded in the `steps`
        property """
        return self._recording

    @recording.setter
    def recording(self, value: bool):
        """ If `True`, the states of motion at each intermediate time step will be recorded in the `steps`
        property. On being reset, clears any previously recorded steps """
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
        """ If, `recording` == `True`, the states of motion at each intermediate time step from the last call to
        `next_impact` """
        return self._steps

    def motion_at_time(self, t: float) -> StateOfMotion:
        """ Returns the state of motion at a given time `t` (does not check for physicality) """

        # Time elapsed since last impact
        lamda = t - self._point.phi

        # Unforced sine/cosine terms for the displacement
        sin_lamda = sin(lamda)
        cos_lamda = cos(lamda)

        # Combine with forcing term for displacement
        # Differentiate for velocity
        return StateOfMotion(t=t,
                             x=self._cos_coeff * cos_lamda + self._sin_coeff * sin_lamda + self._gamma * cos(
                                 self._parameters.omega * t),
                             v=self._sin_coeff * cos_lamda - self._cos_coeff * sin_lamda - self._parameters.omega * self._gamma *
                               sin(self._parameters.omega * t))

    def next_impact(self) -> ImpactPoint:
        """
        Returns the next impact given the currently specified starting impact

        :return: the next impact as a point on the impact surface
        """

        # Start at impact time
        t = self._point.phi

        # Record start point if recording
        self._record_state(self.motion_at_time(t))

        # Initialise step size
        step_size = self._step_size

        # Terminate when bisection algorithm has reduced step size below threshold
        while abs(step_size) > self._limit:
            # Increment time
            t += step_size

            state = self.motion_at_time(t)

            if state.x > self._parameters.sigma:
                # Displacement is above offset so apply bisection algorithm to seek impact time
                if step_size > 0:
                    step_size *= -0.5

            else:
                if step_size < 0:
                    # If we get here then previous displacement was above the offset, so continue to apply bisection
                    # algorithm
                    step_size *= -0.5

                # Only record state if displacement is the right side of the obstacle
                self._record_state(state)

        # Now we have found the impact, return it as a point on the impact surface
        return state.point_from_state(self._parameters.omega)

    def iterate(self) -> ImpactPoint:
        """
        Returns the next impact given the currently specified starting impact AND resets the starting point to the
        new impact

        :return: the next impact as a point on the impact surface
        """
        next_point = self.next_impact()

        self.set_impact(next_point)

        return next_point

    def _record_state(self, state: StateOfMotion) -> None:
        """
        If `recording` == `True`, adds the state of motion to the `steps` list

        :param state: the state to be recorded
        :return:
        """

        if self.recording:

            if self._steps:
                prev_time = self._steps[-1].t

                period = forcing_period(self._parameters.omega)

                while prev_time > state.t + SMALL:
                    state.t += period

            self._steps.append(state)
