defmodule ImposcUtils do
  @moduledoc """
  Documentation for ImposcUtils.
  """

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

  @spec point_to_list(ImpactPoint.t()) :: [...]
  def point_to_list(%ImpactPoint{} = point) do
    [point.phi, point.v]
  end

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
  `:omega`: the forcing frequency
  `:gamma`: the coefficient of the forcing term of the displacement
  `:cos_coeff`: the coefficient of the cosine term of the displacement
  `:sin_coeff`: the coefficient of the sine term of the displacement
  """

  defstruct omega: 2, gamma: -1/3.0, cos_coeff: 1, sin_coeff: 0

  @doc """
  Derives evolution coefficients from the system parameters and the coordinates of the previous impact
  """
  @spec derive(SystemParameters.t(), ImpactPoint.t()) :: EvolutionCoefficients.t()
  def derive(%SystemParameters{} = parameters, %ImpactPoint{} = point) do
    result = %EvolutionCoefficients{gamma: ImposcUtils.gamma(parameters.omega), omega: parameters.omega}
    result = %{result | cos_coeff: parameters.sigma - result.gamma * :math.cos(parameters.omega * point.phi)}
    result = %{result | sin_coeff: -parameters.r * point.v + parameters.omega * result.gamma * :math.sin(parameters.omega * point.phi)}
    result
  end
end

defmodule StateOfMotion do
  @moduledoc """
  State and phase variables for the motion between impacts
  """

  @doc """
  `:x`: the displacement
  `:v`: the velocity = dx/dt
  `:t`: the time
  """

  defstruct x: 0, v: 0, t: 0

  @spec point_from_state(StateOfMotion.t(), float) :: ImpactPoint.t()
  def point_from_state(%StateOfMotion{} = state, omega) do
    %ImpactPoint{phi: ImposcUtils.phi(state.t, omega), v: state.v}
  end
end

defmodule MotionBetweenImpacts do
  @moduledoc """
  Computes the time evolution of the system from one impact to the next
  """

  @doc """
  Gives the state of motion (position, velocity, time) at a given time after an impact
  """
  @spec motion_at_time(number, ImpactPoint.t(), EvolutionCoefficients.t()) :: StateOfMotion.t()
  def motion_at_time(t, %ImpactPoint{} = previous_impact, %EvolutionCoefficients{} = coeffs) do
    lambda = t - previous_impact.phi
    result = %StateOfMotion{t: t}
    result = %{result| x: coeffs.cos_coeff * :math.cos(lambda) + coeffs.sin_coeff * :math.sin(lambda) + coeffs.gamma * :math.cos(coeffs.omega * t)}
    result = %{result| v: coeffs.sin_coeff * :math.cos(lambda) - coeffs.cos_coeff * :math.sin(lambda) - coeffs.omega * coeffs.gamma * :math.sin(coeffs.omega * t)}
    result
  end

  def next_impact(%ImpactPoint{} = previous_impact, %SystemParameters{} = params, step_size \\ 0.1, limit \\ 0.001) do
    coeffs = EvolutionCoefficients.derive(params, previous_impact)
    start_state = %StateOfMotion{t: previous_impact.phi, x: params.sigma, v: -params.r * previous_impact.v}
    StateOfMotion.point_from_state(find_next_impact(start_state, previous_impact, coeffs, params.sigma, step_size, limit), params.omega)
  end

  def find_next_impact(%StateOfMotion{} = state, %ImpactPoint{} = _previous_impact, %EvolutionCoefficients{} = _coeffs, _sigma, step_size, limit) when abs(step_size) < limit do
    state
  end

  def find_next_impact(%StateOfMotion{} = state, %ImpactPoint{} = previous_impact, %EvolutionCoefficients{} = coeffs, sigma, step_size, limit) do
    step_size = new_step_size(step_size, state.x, sigma)
    new_time = state.t + step_size
    new_state = motion_at_time(new_time, previous_impact, coeffs)
    find_next_impact(new_state, previous_impact, coeffs, sigma, step_size, limit)
  end

  def new_step_size(step_size, x, sigma) when x <= sigma and step_size < 0 do
    -0.5 * step_size
  end

  def new_step_size(step_size, x, sigma) when x > sigma and step_size > 0 do
    -0.5 * step_size
  end

  def new_step_size(step_size, _x, _sigma) do
    step_size
  end

  def iterate_impacts(%ImpactPoint{} = start_impact, %SystemParameters{} = params, num_iterations \\ 1000) do
    stream = Stream.unfold(start_impact, &{&1, next_impact(&1, params)})
    Enum.take(stream, num_iterations)
  end

end
