import ImposcUtils
import SystemParameters
import ImpactPoint

defmodule OneNParams do
  @moduledoc """
  Structure for parameters for analysing single-impact (1, n) periodic orbits
  """

  defstruct omega: 2, gamma2: 1/9.0, r_minus: 0.1, n: 1, cs: 0, phase_coeff: 0, sigma_s: 0

  defp derive_cs(cn, _sn, _r) when cn == 1 do
    0
  end

  defp derive_cs(cn, sn, r) do
   sn*(1+r)/(1-cn)
  end

  @spec derive(float, float, integer) :: OneNParams.t()
  def derive(omega, r, n) do
    arg = 2*:math.pi*n/omega
    cn = :math.cos(arg)
    sn = :math.sin(arg)
    gamma = :math.pow(ImposcUtils.gamma(omega),2)

    result = %OneNParams{omega: omega, gamma2: gamma * gamma, r_minus: (1-r)/omega, cs: derive_cs(cn, sn, r)}
    result = %OneNParams{result | phase_coeff: -result.r_minus / gamma / 2}
    result = %OneNParams{result | sigma_s: :math.sqrt(result.gamma2*(1 + :math.pow(result.cs/result.r_minus, 2)))}
    result
  end

  @spec discriminant(number, OneNParams.t()) :: number
  defp discriminant(sigma, %OneNParams{} = params) do
    4 * (params.gamma2*params.cs*params.cs - (sigma  * sigma - params.gamma2) * params.r_minus)
  end

  @spec velocities_for_discr(number, number, OneNParams.t()) :: [nil | float, ...]
  defp velocities_for_discr(_sigma, discriminant, %OneNParams{} = _params) when discriminant < 0 do
    {nil, nil}
  end

  defp velocities_for_discr(sigma, discriminant, %OneNParams{} = params) do
    intercept = -2 * params.cs * sigma
    divisor = params.cs * params.cs + params.r_minus * params.r_minus

    aa = intercept/divisor

    d = :math.sqrt(discriminant) / divisor

    {aa + d, aa - d}
  end

  @spec phase_for_velocity( float | nil, OneNParams.t()) :: float
  defp phase_for_velocity(nil, %OneNParams{} = _params) do
    nil
  end

  defp phase_for_velocity(velocity, %OneNParams{} = params) do
    :math.asin(params.phase_coeff * velocity) / params.omega
  end

  def point_for_velocity(nil, %OneNParams{} = _params) do
    nil
  end

  def point_for_velocity(velocity, %OneNParams{} = params) do
    %ImpactPoint{phi: phase_for_velocity(velocity, params), v: velocity}
  end

  @spec velocities(number, OneNParams.t()) :: {nil | float, nil | float}
  def velocities(sigma, %OneNParams{} = params) do
    Tuple.to_list(velocities_for_discr(sigma, discriminant(sigma, params), params)) |> Enum.map(&nullify_unphysical(&1)) |> List.to_tuple
  end

  @spec orbits(number, OneNParams.t()) :: [any]
  def orbits(sigma, %OneNParams{} = params) do
    Enum.map(velocities(sigma, params), & point_for_velocity(&1 , params))
  end

  @spec nullify_unphysical(any) ::nil | float
  def nullify_unphysical(velocity) do
    if is_physical(velocity) do
      velocity
    else
      nil
    end
  end

  def is_physical(velocity) when velocity < 0 do
    false
  end

  def is_physical(velocity) do
    true
  end
end

defmodule OneNLoci do
  @moduledoc """
  """

  def curves_for_fixed_omega(n, omega, r, num_points \\ 1000) do
    params = OneNParams.derive(omega, r, n)

    delta_s = 2 * params.sigma_s / num_points

    pairs = 0..num_points |> Enum.map(&(&1 * delta_s - params.sigma_s)) |> Enum.map(&({&1, OneNParams.velocities(&1, params)}))

    [pairs |> Enum.map(&{elem(&1,0), elem(elem(&1,1), 0)}) |> Enum.filter(&!is_nil(elem(&1,1))), pairs |> Enum.map(&{elem(&1,0), elem(elem(&1,1), 1)}) |> Enum.filter(&!is_nil(elem(&1,1)))]
  end
end
