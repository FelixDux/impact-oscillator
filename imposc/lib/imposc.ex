defmodule Imposc do
  @moduledoc """
  Documentation for Imposc.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Imposc.hello()
      :world

  """
  def hello do
    :world
  end

  @doc """
  Returns the fractional part of a floating point number
  """
  def frac_part(x) do
    x - trunc(x)
  end

  @doc """
  Returns the remainder of `x` divided by `y` - like `Kernel.rem` but for floats
  """
  @spec modulo(float, float) :: float
  def modulo(x, y) when y == 0 do
    x
  end

  def modulo(x, y) do
    frac_part(x/y)*y
  end

  @doc """
  For a given time `t` returns the phase relative to the forcing period 2 pi /`omega`
  """
  @spec phi(float, float) :: float
  def phi(t, omega) do
    modulo(t,2.0*:math.pi/omega)
  end

  @doc """
  For a forcing frequency `omega` returns 1/(1 - omega ** 2)
  """
  @spec gamma(number) :: float
  def gamma(omega) when omega in [1, -1] do
    1
  end

  def gamma(omega) do
    1.0/(1.0-:math.pow(omega, 2))
  end
end

defmodule ImpactPoint do
  @moduledoc """
  Struct for points on the impact surface
  """

  @doc """
  Each impact is uniquely specified by two parameters:

  `:phi`: the phase (time modulo the forcing period) at which the impact occurs
  `:v`: the velocity of the impact, which cannot be negative

  Because `:phi` is periodic and `:v` non-negative, the surface on which impacts are
  defined is a half-cylinder. Whether a zero-velocity impact is physically meaningful
  depends on the value of `:phi` and on `sigma` the offset of the obstacle from the
  centre of motion.
  """

  defstruct phi: 0, v: 0

end


defmodule SystemParameters do
  @moduledoc """
  Struct for parameters which define a 1-d impact oscillator system with no damping between impacts
  """

  @doc """

  `:omega`: the forcing frequency
  `:r`: the coefficient of restitution at an impact
  `:sigma`: the offset from the centre of motion at which an impact occurs
  """

  defstruct omega: 2, r: 0.8, sigma: 0

end

defmodule EvolutionCoefficients do
  @moduledoc """
  Coefficients for time evolution of the system from one impact to the next
  """

  @doc """
  ':gamma': the coefficient of the forcing term of the displacement
  `:cos_coeff`: the coefficient of the cosine term of the displacement
  `:sin_coeff`: the coefficient of the sine term of the displacement
  """

  defstruct gamma: -1/3.0, cos_coeff: 1, sin_coeff: 0

  @doc """
  Derives evolution coefficients from the system parameter and the coordinates of the previous impact
  """
  @spec derive(SystemParameters.t(), ImpactPoint.t()) :: EvolutionCoefficients.t()
  def derive(%SystemParameters{} = parameters, %ImpactPoint{} = point) do
    result = %EvolutionCoefficients{gamma: Imposc.gamma(parameters.omega)}
    result = %{result | cos_coeff: parameters.sigma - result.gamma * :math.cos(parameters.omega * point.phi)}
    result = %{result | sin_coeff: -parameters.r * point.v + parameters.omega * result.gamma * :math.sin(parameters.omega * point.phi)}
    result
  end
end
