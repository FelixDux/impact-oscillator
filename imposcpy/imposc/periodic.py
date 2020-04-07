"""Classes and functions for analysing single-impact (1, n) periodic orbits, where n is the number of forcing cycles
between impacts.

An algebraic analysis reveals that closed-form expressions for (1, n) orbits can be obtained by solving a quadratic
equation for the impact velocity V_n. For a fixed forcing frequency `omega` and coefficient of restitution `r`,
the impact velocity Vn describes an ellipse in (`sigma`, V_n) space as the obstacle offset `sigma` is varied. Not all
points on the ellipse correspond to physical orbits. In particular, all orbits with Vn < 0 are obviously unphysical.
Further, as one traverses the ellipse anti-clockwise from the point where it intersects the `sigma`-axis for positive
`sigma`, then there is a point on the ellipse before one reaches the intersection with the `sigma`-axis for negative
`sigma`, at which orbits become unphysical - i.e. from an initial impact at (phi_n, V_n) the next impact is at time
before phi_n + n X forcing period. This point cannot be obtained in closed form and has to be computed numerically.

It can further be shown analytically that:

- where it corresponds to physical orbits, the upper branch of the ellipse is always stable and the lower branch is
always unstable
- as `omega` varies, the major axis of the ellipse rotates and it is vertical for `omega` = `n`
"""

from math import cos, sin, pi, sqrt, pow, acos
from typing import Tuple, Optional

from imposcpy.imposc.motion import ImpactPoint, phi, MotionBetweenImpacts
from imposcpy.imposc.parameters import SystemParameters
from imposcpy.imposc.constants import SMALL, SMALL_OMEGA, SMALLISH


class OneNParams:
    """ parameters for analysing single-impact (1, n) periodic orbits """

    def __init__(self, parameters: SystemParameters, n: int):
        """

        :param parameters: a `SystemParameters` instance defining the system (NOTE `parameters`.`sigma` is ignored
        because we are interested in generating the response when varying `sigma`)
        :param n: the number of forcing cycles between each impact
        """
        self._omega = parameters.omega
        self._r = parameters.r
        self._n = n

        # Derive coefficients used in the analysis
        self._r_minus = (1 - self._r) / self._omega

        self._period = 2 * pi * n / self._omega
        self._cn = cos(self._period)
        self._sn = sin(self._period)

        self._cs = 0

        if self._cs != 1:
            self._cs = self._sn * (1 + self._r) / (1 - self._cn)

        self._gamma = parameters.gamma()

        self._gamma2 = self._gamma * self._gamma

        self._phase_coeff = -self._r_minus / self._gamma / 2

        self._sigma_s = sqrt(self._gamma2 * (1 + pow(self._cs / self._r_minus, 2)))

    def discriminant(self, sigma: float) -> float:
        """ The discriminant of the quadratic equation for the impact velocity for a given value of the obstacle
        offset `sigma` """
        return 4 * (self._gamma2 * self._cs * self._cs - (sigma * sigma - self._gamma2) * self._r_minus * self._r_minus)

    def velocities(self, sigma: float) -> Tuple[Optional[float, None], Optional[float, None]]:
        """
        Solves the quadratic equation to return the velocities for candidate (1, n) orbits for a given obstacle
        offset. Depending on the value of the discriminant of the quadratic, there will be either zero, one (in the case
        of a double root) or two such velocities. Unphysical or negative-velocity orbits are not filtered out.

        :param sigma: the obstacle offset
        :return: A tuple comprising two velocities or two `None`s in the case of complex roots. In the case of a double
        root the two velocities will be the same.
        """
        discr = self.discriminant(sigma)

        if discr < 0:
            return None, None
        else:
            intercept = -2 * self._cs * sigma
            divisor = self._cs * self._cs + self._r_minus * self._r_minus

            vs = intercept / divisor

            d = sqrt(discr) / divisor

            return vs + d, vs - d

    def phase_for_velocity(self, v: float, sigma: float) -> Optional[float, None]:
        """
        Returns the phase corresponding to a solution of the quadratic equation for the velocity of a (1, n) orbit

        :param v: the candidate velocity
        :param sigma: the obstacle offset (as used in the quadratic)
        :return: the impact phase for the corresponding (1, n) orbit
        """
        if v is not None:
            arg = (sigma + self._cs * v / 2) / self._gamma

            angle = acos(arg)

            # Check for phase correction. sin(angle) should have opposite sign to v/gamma
            s = sin(angle)
            vg = v / self._gamma
            if (vg > 0 and s > 0) or (vg < 0 and s < 0):
                angle = 2 * pi - angle

            return phi(angle / self._omega, self._omega)
        else:
            return None

    def point_for_velocity(self, v: float, sigma: float) -> Optional[ImpactPoint, None]:
        """
        Returns in `ImpactPoint` corresponding to a solution of the quadratic equation for the velocity of a (1, n)
        orbit.

        :param v: the candidate velocity
        :param sigma: the obstacle offset (as used in the quadratic)
        :return: the point on the impact surface for the corresponding (1, n) orbit
        """
        if v is not None:
            return ImpactPoint(phi=self.phase_for_velocity(v, sigma), v=v)
        else:
            return None

    def orbits(self, sigma: float) -> Tuple[Optional[ImpactPoint, None], Optional[ImpactPoint, None]]:
        """
        Returns points on the impact surface corresponding to physical (1, n) orbits for a given obstacle offset. There
        will be either zero, one (in the case of a double root) or two such points.

        :param sigma: the obstacle offset
        :return: A two-place tuple comprising points on the impact surface corresponding to physical (1, n) orbits or
        `None`s in the case of unphysical orbits or complex roots to the quadratic.
        """
        return tuple([self.point_for_velocity(self.nullify_unphysical(v, sigma), sigma) for v in self.velocities(sigma)])

    def is_physical(self, v: float, sigma: float) -> bool:
        """
        Verifies the physicality of a candidate (1, n) orbit

        :param v: the candidate velocity
        :param sigma: the obstacle offset (as used in the quadratic)
        :return: `True` if the orbit is physical, `False` otherwise
        """
        if v is None or v <= 0:
            return False

        params = SystemParameters(omega=self._omega, r=self._r, sigma=sigma)

        start_point = self.point_for_velocity(v, sigma)

        motion = MotionBetweenImpacts(parameters=params, point=start_point)

        next_point = motion.next_impact()

        # Should be periodic

        return abs(next_point.v - start_point.v) / start_point.v < SMALL and abs(next_point.phi - start_point.phi) < \
               SMALLISH * self._period

    def nullify_unphysical(self, v: float, sigma: float) -> Optional[float, None]:
        """
        Filters out a candidate (1, n) orbit if it is unphysical

        :param v: the candidate velocity
        :param sigma: the obstacle offset (as used in the quadratic)
        :return: the candidate velocity if the orbit is physical, `None` otherwise
        """
        if self.is_physical(v, sigma):
            return v
        else:
            return None

    def __str__(self) -> str:
        """ Human-readable string representation """
        return f"{SMALL_OMEGA} = {self._omega}, r = {self._r}, n = {self._n}"

    def __repr__(self) -> str:
        """ An unambiguous string representation """
        return f"<{self.__class__.__name__}: {self.__str__()}>"

    @property
    def sigma_s(self) -> float:
        """ The positive intercept with the `sigma`-axis"""
        return self._sigma_s


def curves_for_fixed_omega(n: int, parameters: SystemParameters, num_points=1000):
    """
    Generates a `sigma`-response curve for a given forcing multiple and set of system parameters
    :param n: the number of forcing cycles between each impact
    :param parameters: a `SystemParameters` instance defining the system (NOTE `parameters`.`sigma` is ignored
        because we are interested in generating the response when varying `sigma`)
    :param num_points: the number of data points to record
    :return:
    """
    params = OneNParams(n=n, parameters=parameters)

    delta_s = 2 * params.sigma_s / (num_points - 1)

    sigmas = [i * delta_s - params.sigma_s for i in range(num_points)]

    pairs = [tuple([params.nullify_unphysical(v, sigma) for v in params.velocities(sigma)]) for sigma in sigmas]

    return sigmas, pairs, str(params)


if __name__ == '__main__':
    sys_params = SystemParameters(omega=2,r=0.8, sigma=0)

    one_n_params = OneNParams(parameters=sys_params, n=1)

    num_points = 10

    delta_s = 2 * one_n_params.sigma_s / (num_points - 1)

    sigmas = [i * delta_s - one_n_params.sigma_s for i in range(num_points)]

    pairs = [(sigma, one_n_params.velocities(sigma)) for sigma in sigmas]

    [print(pair, one_n_params.phase_for_velocity(pair[1][0], pair[0])) for pair in pairs]