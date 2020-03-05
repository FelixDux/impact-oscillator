from math import pi
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


class EvolutionCoefficients:
    """ Coefficients for time evolution of the system from one impact to the next """


if __name__ == "__main__":
    print(phi(3, pi))