from math import pi, cos, sin
from dataclasses import dataclass

SMALL = 0.001

def phi(t: float, omega: float) -> float:
    """
    For a given time `t` returns the phase relative to the forcing period 2 pi /`omega`
    """
    if omega == 0:
        return t
    else:
        return t % 2.0 * pi / omega

def gamma(omega: float) -> float:
    if abs(omega) == 1:
        return 1
    else:
        return 1.0/(1.0-:math.pow(omega, 2))


@dataclass
class SystemParameters:
    """
    Parameters which define a 1-d impact oscillator system with no damping between impacts
    """
    omega: float  # the forcing frequency
    r: float      # the coefficient of restitution at an impact
    sigma: float  # the offset from the centre of motion at which an impact occurs


@dataclass
class ImpactPoint:
    """
    A point on the impact surface
    """
    phi: float
    v: float


class EvolutionCoefficients:
    """ Coefficients for time evolution of the system from one impact to the next """

    def __init__(self, parameters: SystemParameters, point: ImpactPoint):
        self._parameters = parameters
        self._gamma = gamma(parameters.omega)  # the coefficient of the forcing term of the displacement
        self._cos_coeff = parameters.sigma - result.gamma * cos(parameters.omega * point.phi)
        self._sin_coeff = -parameters.r * point.v + parameters.omega * result.gamma * sin(parameters.omega * point.phi)



if __name__ == "__main__":
    print(phi(3, pi))