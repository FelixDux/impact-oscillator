defmodule EvolutionCoefficients do
  @moduledoc """
  Coefficients for time evolution of the system from one impact to the next
  """

  @doc """
  `:omega`: the forcing frequency
  `:gamma`: the coefficient of the forcing term of the displacement
  `:cos_coeff`: the coefficient of the cosine term of the displacement
  `:sin_coeff`: the coefficient of the sine term of the displacement
  `:sticking_region`: the range of phases for which zero-velocity impacts stick
  """

  defstruct omega: 2,
            gamma: -1 / 3.0,
            cos_coeff: 1,
            sin_coeff: 0,
            sticking_region: %StickingRegion{}

  @doc """
  Derives evolution coefficients from the system parameters and the coordinates of the previous impact

  `:parameters`: system parameters for the oscillator
  `:point`: coordinates of the previous impact on the impact surface

  Returns `:EvolutionCoefficients` for the motion after the impact
  """

  @spec derive(SystemParameters, ImpactPoint) :: EvolutionCoefficients
  def derive(%SystemParameters{} = parameters, %ImpactPoint{} = point) do
    result = %EvolutionCoefficients{
      gamma: ForcingPhase.gamma(parameters.omega),
      omega: parameters.omega
    }

    result = %{
      result
      | cos_coeff: parameters.sigma - result.gamma * :math.cos(parameters.omega * point.phi)
    }

    result = %{
      result
      | sin_coeff:
          -parameters.r * point.v +
            parameters.omega * result.gamma * :math.sin(parameters.omega * point.phi)
    }

    result = %{result | sticking_region: StickingRegion.derive(parameters)}
    result
  end
end
