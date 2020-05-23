"""
Parameters which define a 1-d impact oscillator system with no damping between impacts in dimensionless variables
"""

from math import pow
from dataclasses import dataclass

from imposcpy.imposc.constants import SMALL, SMALL_OMEGA, SMALL_SIGMA


@dataclass
class SystemParameters:
    """
    Parameters which define a 1-d impact oscillator system with no damping between impacts in dimensionless variables
    """
    omega: float  # the forcing frequency
    r: float      # the coefficient of restitution at an impact
    sigma: float  # the offset from the centre of motion at which an impact occurs

    def gamma(self) -> float:
        """ The coefficient of the forcing term in the equation for the displacement between impacts """
        if abs(self.omega) == 1:
            return 1
        else:
            return 1.0/(1.0-pow(self.omega, 2))

    def __str__(self) -> str:
        """ A human-readable string representation """
        return f"{SMALL_OMEGA} = {self.omega}, {SMALL_SIGMA} = {self.sigma}, r = {self.r}"

    def __repr__(self) -> str:
        """ An unambiguous string representation """
        return f"<{self.__class__.__name__}: {self.__str__()}>"
