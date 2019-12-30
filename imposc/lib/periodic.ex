import ImposcUtils
import SystemParameters

defmodule PeriodicParams do
  @moduledoc """
  Structure for parameters for analysing single-impact periodic orbits
  """

  defstruct gamma2: 1/9.0, r_minus: 0.1, n: 1, cs: 0

  def _derive_cs(cn, _sn) when cn == 1 do
    0
  end

  def _derive_cs(cn, sn, r) do
   sn*(1+r)/(1-cn)
  end

  @spec derive(SystemParameters.t(), integer) :: PeriodicParams.t()
  def derive(%SystemParameters{} = parameters, n) do
    arg = 2*:math.pi*n/parameters.omega
    cn = :math.cos(arg)
    sn = :math.sin(arg)

    result = %PeriodicParams{gamma2: :math.pow(ImposcUtils.gamma(parameters.omega),2), r_minus: (1-parameters.r)/parameters.omega, cs: _derive_cs(cn, sn, parameters.r)}

    result
  end

  @spec discriminant(number, PeriodicParams.t()) :: number
  def discriminant(sigma, %PeriodicParams{} = params) do
    cs2 = params.cs * params.cs
    sigma2 = sigma * sigma

    4 * (params.gamma2*params.cs*params.cs - (sigma2 - params.gamma2) * params.r_minus)
  end

  @spec velocity(number, number, PeriodicParams.t()) :: [float, ...]
  def velocity(sigma, discriminant, %PeriodicParams{} = params) do
    intercept = -2 * params.cs * sigma
    divisor = params.cs * params.cs + params.r_minus * params.r_minus

    aa = intercept/divisor

    d = :math.sqrt(discriminant) / divisor

    [aa + d, aa - d]
  end
end
