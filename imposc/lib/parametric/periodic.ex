import ImposcConstants
import SystemParameters

defmodule OneNParams do
  @moduledoc """
  Structure for parameters for analysing single-impact (1, n) periodic orbits as the obstacle offset sigma varies
  """

  @doc """
  `:omega`: the forcing frequency
  `:r`: the coefficient of restitution at an impact
  `:gamma`: the coefficient of the forcing term in the equation for the displacement between impacts
  `:gamma2`: square of the coefficient of the forcing term in the equation for the displacement between impacts
  `:r_minus`: (1 - r)/omega - a coefficient used in the analysis
  `:n`: the number of forcing cycles between each impact
  `:cs`: a coefficient used in the analysis
  `:sigma_s`: The positive intercept with the sigma-axis
  `:period`: The period between impacts
  """

  defstruct omega: 2,
            r: 0.8,
            gamma: 1 / 3.0,
            gamma2: 1 / 9.0,
            r_minus: 0.1,
            n: 1,
            cs: 0,
            sigma_s: 0,
            period: :math.pi()

  @type t :: %OneNParams{
          omega: number(),
          r: number(),
          gamma: number(),
          gamma2: number(),
          r_minus: number(),
          n: integer(),
          cs: number(),
          sigma_s: number(),
          period: number()
        }

  defp derive_cs(cn, _sn, _r) when cn == 1 do
    0
  end

  defp derive_cs(cn, sn, r) do
    sn * (1 + r) / (1 - cn)
  end

  @doc """
  Derives a `:OneNParams` instance from a minimal parameter set

  `:omega`: the forcing frequency
  `:r`: the coefficient of restitution at an impact
  `:n`: the number of forcing cycles between impacts in a single-impact periodic orbit
  """

  @spec derive(number(), number(), integer()) :: {atom(), %OneNParams{}}
  def derive(_omega, _r, n) when not is_integer(n) do
    {:error, "The multiple of the forcing period must be an integer"}
  end

  def derive(_omega, _r, n) when n <= 0 do
    {:error, "The multiple of the forcing period must be a positive integer"}
  end

  def derive(_omega, r, _n) when r < 0 or r > 1 do
    {:error, "The coefficient of restitution must be in the range [0, 1]"}
  end

  def derive(_omega, r, _n) when r == 1 do
    # TODO: implement this (Vn = -(sigma -/+ gamma)(1 - cn)/sn, so not an ellipse any more, sigma_s = abs(gamma))
    {:error, "The case for coefficient of restitution == 1 has not yet been implemented"}
  end

  def derive(omega, r, n) do
    outcome = ForcingPhase.forcing_period(omega)

    case outcome do
      {:ok, forcing_period} ->
        (fn ->
           period = n * forcing_period
           cn = :math.cos(period)
           sn = :math.sin(period)
           gamma = ForcingPhase.gamma(omega)

           result = %OneNParams{
             omega: omega,
             r: r,
             gamma2: gamma * gamma,
             r_minus: (1 - r) / omega,
             cs: derive_cs(cn, sn, r)
           }

           result = %OneNParams{
             result
             | sigma_s: :math.sqrt(result.gamma2 * (1 + :math.pow(result.cs / result.r_minus, 2)))
           }

           result = %OneNParams{result | period: period, gamma: gamma}

           {:ok, result}
         end).()

      {:error, _} ->
        outcome
    end
  end

  @spec discriminant(number(), %OneNParams{}) :: number()
  defp discriminant(sigma, %OneNParams{} = params) do
    # The discriminant of the quadratic equation for the impact velocity for a given value of the obstacle offset.
    4 *
      (params.gamma2 * params.cs * params.cs -
         (sigma * sigma - params.gamma2) * params.r_minus * params.r_minus)
  end

  @spec velocities_for_discr(number(), number(), OneNParams.t()) :: [nil | number(), ...]
  #  Solves the quadratic equation to return the velocities for candidate (1, n) orbits for a given obstacle offset and
  #  discriminant. Depending on the value of the discriminant, there will be either zero, one (in the case of a double
  #  root) or two such velocities. Unphysical or negative-velocity orbits are not filtered out.
  defp velocities_for_discr(_sigma, discriminant, %OneNParams{} = _params)
       when discriminant < 0 do
    # Complex roots
    [nil, nil]
  end

  defp velocities_for_discr(sigma, discriminant, %OneNParams{} = params) do
    # Real roots
    # TODO: case cs == 0
    intercept = -2 * params.cs * sigma
    divisor = params.cs * params.cs + params.r_minus * params.r_minus

    vs = intercept / divisor

    d = :math.sqrt(discriminant) / divisor

    [vs + d, vs - d]
  end

  @spec phase_for_velocity(nil | number(), number(), OneNParams.t()) :: nil | number()
  # Returns the phase corresponding to a solution of the quadratic equation for the velocity of a (1, n) orbit.
  defp phase_for_velocity(nil, _sigma, %OneNParams{} = _params) do
    # Return `nil` for a `nil` velocity
    nil
  end

  defp phase_for_velocity(velocity, sigma, %OneNParams{} = params) do
    arg = (sigma + params.cs * velocity / 2.0) / params.gamma

    angle = :math.acos(arg)

    # Check for phase correction. sin(angle) should have opposite sign to v/gamma
    s = :math.sin(angle)
    vg = velocity / params.gamma

    angle =
      cond do
        (vg > 0 and s > 0) or (vg < 0 and s < 0) -> 2 * :math.pi() - angle
        true -> angle
      end

    ForcingPhase.phi(angle / params.omega, params.omega)
  end

  #  Returns an `:ImpactPoint` corresponding to a solution of the quadratic equation for the velocity of a (1, n)
  #  orbit.
  #
  #  `:velocity`: impact velocity for a candidate (1, n) orbit
  #  `:sigma`: the obstacle offset
  #  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  defp point_for_velocity(nil, _sigma, %OneNParams{} = _params) do
    nil
  end

  defp point_for_velocity(velocity, sigma, %OneNParams{} = params) do
    phase_for_velocity(velocity, sigma, params) |> (&%ImpactPoint{phi: &1, v: velocity, t: &1}).()
  end

  @doc """
  Returns impact velocities corresponding to physical (1, n) orbits for a given obstacle offset. There will be
  either zero, one (in the case of a double root) or two such velocities.

  `:sigma`: the obstacle offset
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  """

  @spec velocities(number(), %OneNParams{}) :: {nil | number(), nil | number()}
  def velocities(sigma, %OneNParams{} = params) do
    velocities_for_discr(sigma, discriminant(sigma, params), params)
    |> Enum.map(&nullify_unphysical(&1, sigma, params))
    |> List.to_tuple()
  end

  @doc """
  Returns points on the impact surface corresponding to physical (1, n) orbits for a given obstacle offset. There
  will be either zero, one (in the case of a double root) or two such points.

  `:sigma`: the obstacle offset
  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  """

  @spec orbits(number(), %OneNParams{}) :: [nil | %ImpactPoint{}]
  def orbits(sigma, %OneNParams{} = params) do
    velocities(sigma, params)
    |> Tuple.to_list()
    |> Enum.map(&point_for_velocity(&1, sigma, params))
  end

  #  Filters out velocities for unphysical (1, n) orbits.
  #
  #  `:velocity`: impact velocity for a candidate (1, n) orbit
  #  `:sigma`: the obstacle offset
  #  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  #
  #  Returns `:velocity` if physical, `:nil` if unphysical.
  @spec nullify_unphysical(number() | nil, number(), %OneNParams{}) :: number() | nil
  defp nullify_unphysical(velocity, sigma, %OneNParams{} = params) do
    cond do
      is_nil(velocity) -> nil
      is_physical?(velocity, sigma, params) -> velocity
      true -> nil
    end
  end

  #  Checks whether a candidate (1, n) orbit is physical.
  #
  #  `:velocity`: impact velocity for a candidate (1, n) orbit
  #  `:sigma`: the obstacle offset
  #  `:params`: parameters held fixed as the offset varies for a specified (1, n) orbit
  #
  #  Returns `:true` if physical, `:false` if unphysical.
  @spec is_physical?(number(), number(), %OneNParams{}) :: boolean()
  defp is_physical?(velocity, _sigma, %OneNParams{} = _params) when velocity < 0 do
    # Negative velocity so can't be physical
    false
  end

  defp is_physical?(velocity, sigma, %OneNParams{} = params) do
    if velocity == 0 and sigma > 0 do
      # Special case: periodic graze orbit. Assume physical
      true
    else
      # Verify numerically by computing next impact
      point = point_for_velocity(velocity, sigma, params)

      sys_params = %SystemParameters{omega: params.omega, r: params.r, sigma: sigma}

      # Should be periodic
      MotionBetweenImpacts.next_impact(point, sys_params)
      |> (&elem(&1, 0)).()
      |> (fn next_point ->
            cond do
              abs(point.v) < const_small() && next_point.v > const_small() ->
                false

              point.v != next_point.v and abs(point.v - next_point.v) / point.v > const_small() ->
                false

              abs(point.phi - next_point.phi) > const_smallish() * params.period ->
                false

              true ->
                true
            end
          end).()
    end
  end
end

defmodule OneNLoci do
  @moduledoc """
  """

  def curves_for_fixed_omega(n, omega, r, num_points \\ 1000) do
    # Initialise parameters
    case OneNParams.derive(omega, r, n) do
      {:ok, params} ->
        (fn ->
           # Compute (1, n) velocities over range of offsets
           delta_s = 2 * params.sigma_s / num_points

           pairs =
             0..num_points
             |> Stream.map(&(&1 * delta_s - params.sigma_s))
             |> Stream.map(&{&1, OneNParams.velocities(&1, params)})

           # Filter out unphysical (nullified) velocities
           filter_pairs = fn n ->
             pairs
             |> Enum.map(&{elem(&1, 0), elem(elem(&1, 1), n)})
             |> Enum.filter(&(!is_nil(elem(&1, 1))))
           end

           0..1 |> Enum.map(&filter_pairs.(&1)) |> (&{:ok, &1}).()
         end).()

      {:error, reason} ->
        {:error, reason}
    end
  end

  def vs(n, omega, r) do
    case OneNParams.derive(omega, r, n) do
      {:ok, params} -> OneNParams.velocities(-params.sigma_s, params)
      {:error, reason} -> {:error, reason}
    end
  end

  def orbits_for_params(%SystemParameters{} = params, n) do
    case OneNParams.derive(params.omega, params.r, n) do
      {:ok, parameters} -> OneNParams.orbits(params.sigma, parameters)
      {:error, reason} -> {:error, reason}
    end
  end
end
