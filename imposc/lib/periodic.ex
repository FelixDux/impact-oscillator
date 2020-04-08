import ImposcUtils
import SystemParameters
import ImpactPoint

defmodule OneNParams do
  @moduledoc """
  Structure for parameters for analysing single-impact (1, n) periodic orbits as the obstacle offset sigma varies
  """
  
  @doc """
  `:omega`: the forcing frequency
  `:r`: the coefficient of restitution at an impact
  `:gamma2`: square of the coefficient of the forcing term in the equation for the displacement between impacts
  `:r_minus`: (1 - r)/omega - a coefficient used in the analysis
  `:n`: the number of forcing cycles between each impact
  `:cs`: a coefficient used in the analysis
  `:phase_coeff`: ABOUT TO GO?
  `:sigma_s`: The positive intercept with the sigma-axis
  `:period`: The period between impacts
  """

  defstruct omega: 2, r: 0.8, gamma2: 1/9.0, r_minus: 0.1, n: 1, cs: 0, phase_coeff: 0, sigma_s: 0, period: :math.pi

  defp derive_cs(cn, _sn, _r) when cn == 1 do
    0
  end

  defp derive_cs(cn, sn, r) do
   sn*(1+r)/(1-cn)
  end

  @doc """
  Derives a `:OneNParams` instance from a minimal parameter set

  `:omega`: the forcing frequency
  `:r`: the coefficient of restitution at an impact
  `:n`: the number of forcing cycles between impacts in a single-impact periodic orbit
  """

  @spec derive(float, float, integer) :: OneNParams
  def derive(omega, r, n) do
    period = 2*:math.pi*n/omega
    cn = :math.cos(period)
    sn = :math.sin(period)
    gamma = ImposcUtils.gamma(omega)

    result = %OneNParams{omega: omega, r: r, gamma2: gamma * gamma, r_minus: (1-r)/omega, cs: derive_cs(cn, sn, r)}
    result = %OneNParams{result | phase_coeff: -result.r_minus / gamma / 2}
    result = %OneNParams{result | sigma_s: :math.sqrt(result.gamma2*(1 + :math.pow(result.cs/result.r_minus, 2)))}
    result = %OneNParams{result | period: period}
    result
  end

  @doc """
  The discriminant of the quadratic equation for the impact velocity for a given value of the obstacle offset.

  `:sigma`: the obstacle offset
  `:params`: parameters held fixes as the offset varies for a specified (1, n) orbit
  """

  @spec discriminant(number, OneNParams) :: number
  defp discriminant(sigma, %OneNParams{} = params) do
    4 * (params.gamma2*params.cs*params.cs - (sigma  * sigma - params.gamma2) * params.r_minus * params.r_minus)
  end

  @doc """
  Solves the quadratic equation to return the velocities for candidate (1, n) orbits for a given obstacle offset and
  discriminant. Depending on the value of the discriminant, there will be either zero, one (in the case of a double
  root) or two such velocities. Unphysical or negative-velocity orbits are not filtered out.

  `:sigma`: the obstacle offset
  `:discriminant`: the discriminant of the quadratic for the impact velocities
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit

  Returns a list comprising the two velocities or two `:nil`s if there are no real roots. In the case of a double
        root the two velocities will be the same.
  """

  @spec velocities_for_discr(number, number, OneNParams) :: [nil | float, ...]
  defp velocities_for_discr(_sigma, discriminant, %OneNParams{} = _params) when discriminant < 0 do
    # Complex roots
    [nil, nil]
  end

  defp velocities_for_discr(sigma, discriminant, %OneNParams{} = params) do
    # Real roots
    intercept = -2 * params.cs * sigma
    divisor = params.cs * params.cs + params.r_minus * params.r_minus

    vs = intercept/divisor

    d = :math.sqrt(discriminant) / divisor

    [vs + d, vs - d]
  end

  @doc """
  Returns the phase corresponding to a solution of the quadratic equation for the velocity of a (1, n) orbit.

  `:velocity`: impact velocity for a candidate (1, n) orbit
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  """

  @spec phase_for_velocity( float | nil, OneNParams) :: float
  defp phase_for_velocity(nil, %OneNParams{} = _params) do
    nil
  end

  defp phase_for_velocity(velocity, %OneNParams{} = params) do
    # TODO: modify to use cos formula
    ImposcUtils.phi(:math.asin(params.phase_coeff * velocity) / params.omega, params.omega)
  end

  @doc """
  Returns an `:ImpactPoint` corresponding to a solution of the quadratic equation for the velocity of a (1, n)
  orbit.

  `:velocity`: impact velocity for a candidate (1, n) orbit
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  """

  def point_for_velocity(nil, %OneNParams{} = _params) do
    nil
  end

  def point_for_velocity(velocity, %OneNParams{} = params) do
    %ImpactPoint{phi: phase_for_velocity(velocity, params), v: velocity}
  end

  @doc """
  Returns impact velocities corresponding to physical (1, n) orbits for a given obstacle offset. There will be
  either zero, one (in the case of a double root) or two such velocities.

  `:sigma`: the obstacle offset
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  """

  @spec velocities(number, OneNParams) :: {nil | float, nil | float}
  def velocities(sigma, %OneNParams{} = params) do
    velocities_for_discr(sigma, discriminant(sigma, params), params) |> Enum.map(&nullify_unphysical(&1, sigma, params)) |> List.to_tuple
  end

  @doc """
  Returns points on the impact surface corresponding to physical (1, n) orbits for a given obstacle offset. There
  will be either zero, one (in the case of a double root) or two such points.

  `:sigma`: the obstacle offset
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  """

  @spec orbits(number, OneNParams) :: [any]
  def orbits(sigma, %OneNParams{} = params) do
    velocities(sigma, params) |> Tuple.to_list |> Enum.map(& point_for_velocity(&1 , params))
  end

  @doc """
  Filters out velocities for unphysical (1, n) orbits.

  `:velocity`: impact velocity for a candidate (1, n) orbit
  `:sigma`: the obstacle offset
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit

  Returns `:velocity` if physical, `:nil` if unphysical.
  """

  @spec nullify_unphysical(any, any, OneNParams) :: any
  def nullify_unphysical(velocity, sigma, %OneNParams{} = params) do
    if is_physical?(velocity, sigma, params) do
      velocity
    else
      nil
    end
  end

  @doc """
  Checks whether a candidate (1, n) orbit is physical.

  `:velocity`: impact velocity for a candidate (1, n) orbit
  `:sigma`: the obstacle offset
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit

  Returns `:true` if physical, `:false` if unphysical.
  """

  @spec is_physical?(float, float, OneNParams) :: boolean
  def is_physical?(velocity, _sigma, %OneNParams{} = _params) when velocity < 0 do
    # Negative velocity so can't be physical
    false
  end

  def is_physical?(velocity, sigma, %OneNParams{} = params) do
    # Verify numerically by computing next impact
    point = point_for_velocity(velocity, params)

    sys_params = %SystemParameters{omega: params.omega, r: params.r, sigma: sigma}

    import MotionBetweenImpacts

    {next_point, _} = MotionBetweenImpacts.next_impact(point, sys_params)

    # Should be periodic
    if abs(point.v - point.v) < ImposcUtils.const_small() and
       abs(point.phi - next_point.phi) <  ImposcUtils.const_small() * params.period do
      true
    else
      false
    end
  end
end

defmodule OneNLoci do
  @moduledoc """
  """

  def curves_for_fixed_omega(n, omega, r, num_points \\ 1000) do
    params = OneNParams.derive(omega, r, n)

    delta_s = 2 * params.sigma_s / num_points

    pairs = 0..num_points |> Stream.map(&(&1 * delta_s - params.sigma_s)) |> Stream.map(&({&1, OneNParams.velocities(&1, params)}))

    [pairs |> Enum.map(&{elem(&1,0), elem(elem(&1,1), 0)}) |> Enum.filter(&!is_nil(elem(&1,1))), pairs |> Enum.map(&{elem(&1,0), elem(elem(&1,1), 1)}) |> Enum.filter(&!is_nil(elem(&1,1)))]
  end

  def vs(n, omega, r) do
    params = OneNParams.derive(omega, r, n)

    OneNParams.velocities(-params.sigma_s, params)
  end

  def orbits_for_params(%SystemParameters{} = params, n) do
    OneNParams.orbits(params.sigma, OneNParams.derive(params.omega, params.r, n))
  end
end
