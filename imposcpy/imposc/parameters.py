from math import pow
from dataclasses import dataclass

SMALL = 0.001


@dataclass
class SystemParameters:
    """
    Parameters which define a 1-d impact oscillator system with no damping between impacts
    """
    omega: float  # the forcing frequency
    r: float      # the coefficient of restitution at an impact
    sigma: float  # the offset from the centre of motion at which an impact occurs

    def gamma(self) -> float:
        if abs(self.omega) == 1:
            return 1
        else:
            return 1.0/(1.0-pow(self.omega, 2))