from math import cos, sin, sqrt, pi, sqrt, pow, asin
from typing import Tuple

from imposcpy.imposc.motion import ImpactPoint, phi, MotionBetweenImpacts
from imposcpy.imposc.parameters import SystemParameters
from imposcpy.imposc.constants import SMALL, SMALL_OMEGA


class OneNParams:
    """ parameters for analysing single-impact (1, n) periodic orbits """

    def __init__(self, parameters: SystemParameters, n: int):
        self._omega = parameters.omega
        self._r = parameters.r
        self._n = n

        self._r_minus = (1-self._r)/ self._omega

        arg = 2*pi*n/self._omega
        self._cn = cos(arg)
        self._sn = sin(arg)

        self._cs = 0

        if self._cs != 1:
            self._cs = self._sn*(1 + self._r) / (1 - self._cn)

        gamma = parameters.gamma()

        self._gamma2 = gamma * gamma

        self._phase_coeff = -self._r/ gamma / 2

        self._sigma_s = sqrt(self._gamma2*(1 + pow(self._cs/self._r_minus, 2)))

    def discriminant(self, sigma: float) -> float:
        return 4 * (self._gamma2*self._cs*self._cs - (sigma  * sigma - self._gamma2) * self._r_minus * self._r_minus)

    def velocities(self, sigma: float) -> Tuple[float, float]:
        discr = self.discriminant(sigma)

        if discr < 0:
            return None, None
        else:            
            intercept = -2 * self._cs * sigma
            divisor = self._cs * self._cs + self._r_minus * self._r_minus

            vs = intercept/divisor

            d = sqrt(discr) / divisor

            return vs + d, vs - d

    def phase_for_velocity(self, v: float) -> float:
        if v is not None:
            return phi(asin(self._phase_coeff * v) / self._omega, self._omega)
        else:
            return None

    def point_for_velocity(self, v: float) -> ImpactPoint:
        if v is not None:
            return ImpactPoint(phi=self.phase_for_velocity(v), v=v)
        else:
            return None

    def orbits(self, sigma: float) -> Tuple[ImpactPoint, ImpactPoint]:
        return tuple([self.point_for_velocity(self.nullify_unphysical(v, sigma)) for v in self.velocities(sigma)])

    def is_physical(self, v: float, sigma: float) -> bool:
        if v < 0:
            return False

        params = SystemParameters(omega=self._omega, r=self._r, sigma=sigma)

        start_point = self.point_for_velocity(v)

        motion = MotionBetweenImpacts(parameters=params, point=start_point)

        next_point = motion.next_impact()

        # Should be periodic

        return abs(next_point.v - start_point.v) < SMALL

    def nullify_unphysical(self, v: float, sigma: float) -> float:
        if self.is_physical(v, sigma):
            return v
        else:
            return None

    def __str__(self) -> str:
        return f"{SMALL_OMEGA} = {self._omega}, r = {self._r}, n = {self._n}"

    @property
    def sigma_s(self) -> float:
        return self._sigma_s


# def vs(n: int, parameters: SystemParameters):
#     params = OneNParams(n=n, parameters=parameters)

#     return params.velocities(-params.sigma_s, params)

# def orbits_for_params(n: int, parameters: SystemParameters):
#     params = OneNParams(n=n, parameters=parameters)

#     return params.orbits(params.sigma)

def curves_for_fixed_omega(n: int, parameters: SystemParameters, num_points = 1000):
    params = OneNParams(n=n, parameters=parameters)

    delta_s = 2 * params.sigma_s / num_points

    sigmas = [i * delta_s - params.sigma_s for i in range(num_points)]

    pairs = [params.velocities(sigma) for sigma in sigmas]

    return sigmas, pairs, str(params)