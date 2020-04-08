defmodule ImposcUtils do
  @moduledoc """
  Utility functions and constants for impact oscillator computations.
  """

  @doc """
  Returns the fractional part of a floating point number
  """

  @spec frac_part(float) :: float
  def frac_part(x) do
    x - trunc(x)
  end

  @doc """
  Returns the remainder of `:x` divided by `:y` - like `Kernel.rem` but for floats
  """

  @spec modulo(float, float) :: float
  def modulo(x, y) when y == 0 do
    x
  end

  def modulo(x, y) when y < 0 do
   modulo(x, abs(y))
  end

  def modulo(x, y) when x < 0 do
   modulo(x + y, y)
  end

  def modulo(x, y) do
    x - trunc(x/y)*y
  end

  @doc """
  For a given time `:t` returns the phase relative to the forcing period 2 `math.pi` /`:omega`
  """

  @spec phi(float, float) :: float
  def phi(t, omega) do
    modulo(t,2.0*:math.pi/omega)
  end

  @doc """
  For a forcing frequency `:omega` returns the coefficient of the forcing term in the equation for
  the displacement between impacts
  """

  @spec gamma(number) :: float
  def gamma(omega) when omega in [1, -1] do
    1
  end

  def gamma(omega) do
    1.0/(1.0-:math.pow(omega, 2))
  end

  @doc """
  Tolerance for floating point comparisons
  """

  defmacro const_small do
    quote do: 0.001
  end

  @doc """
  Unicode Greek letter sigma
  """

  defmacro const_sigma do
    quote do: List.to_string([<<207_131::utf8>>])
  end

  @doc """
  Unicode Greek letter omega
  """

  defmacro const_omega do
    quote do: List.to_string([<<207_137::utf8>>])
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

  @doc """
  Converts the struct to a list [`:phi`, `:v`].
  """

  @spec point_to_list(ImpactPoint) :: [float]
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

  `:parameters`: system parameters for the oscillator
  `:point`: coordinates of the previous impact on the impact surface

  Returns `:EvolutionCoefficients` for the motion after the impact
  """

  @spec derive(SystemParameters, ImpactPoint) :: EvolutionCoefficients
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

  @doc """
  Derives a point on the impact surface from a state of motion. In general this is only meaningful if the displacement
  `:state.x` is equal to the obstacle offset `:SystemParameters.sigma` but the mathematical construction only relies on
  the forcing frequency `:omega`.

  `:state`: the current state of motion
  `:omega`: the (dimensionless) forcing frequency

  Returns a point on the impact surface `:state.x`=`:SystemParameters.sigma`
  """

  @spec point_from_state(StateOfMotion, float) :: ImpactPoint
  def point_from_state(%StateOfMotion{} = state, omega) do
    %ImpactPoint{phi: ImposcUtils.phi(state.t, omega), v: state.v}
  end
end

defmodule MotionBetweenImpacts do
  @moduledoc """
  Computes the time evolution of the system from one impact to the next
  """

  @typedoc """
  Tuple comprising an `:ImpactPoint` and a list which optionally contains `:StateOfMotion` instances for time steps
  from the previous impact.
  """

  @type point_with_states :: {ImpactPoint, [StateOfMotion]}

  @doc """
  Gives the state of motion (position, velocity, time) at a given time after an impact

  `:t`: time into the simulation
  `:previous_impact`: the point on the impact surface corresponding to the previous impact
  `:coeffs`: the coefficients governing the motion after the previous impact

  Returns the `:StateOfMotion` at time `:t`
  """

  @spec motion_at_time(number, ImpactPoint, EvolutionCoefficients) :: StateOfMotion
  def motion_at_time(t, %ImpactPoint{} = previous_impact, %EvolutionCoefficients{} = coeffs) do
    # Time since the previous impact
    lambda = t - previous_impact.phi

    result = %StateOfMotion{t: t}

    # Displacement
    result = %{result| x: coeffs.cos_coeff * :math.cos(lambda) + coeffs.sin_coeff * :math.sin(lambda) + coeffs.gamma *
      :math.cos(coeffs.omega * t)}

    # Velocity
    result = %{result| v: coeffs.sin_coeff * :math.cos(lambda) - coeffs.cos_coeff * :math.sin(lambda) - coeffs.omega *
      coeffs.gamma * :math.sin(coeffs.omega * t)}

    result
  end

  @doc """
  Returns the next impact given the a specified starting impact.

  `:previous_impact`: the specified starting impact
  `:params`: the parameters governing the system behaviour
  `:record_states`: specifies whether intermediate states of motion will be returned
  `:step_size`: the initial time step size (the search algorithm will reduce this)

  Returns a `t:point_with_states/0` with the next impact point and optionally the intermediate states of motion
  """

  @spec next_impact(ImpactPoint, SystemParameters, Boolean, number, number) :: point_with_states
  def next_impact(%ImpactPoint{} = previous_impact, %SystemParameters{} = params, record_states \\ false, step_size \\ 0.1, limit \\ 0.001) do
    coeffs = EvolutionCoefficients.derive(params, previous_impact)
    start_state = %StateOfMotion{t: previous_impact.phi, x: params.sigma, v: -params.r * previous_impact.v}
    states = find_next_impact(start_state, previous_impact, coeffs, params.sigma, record_states, step_size, limit)
    {StateOfMotion.point_from_state(Enum.at(states, -1), params.omega), states}
  end

  @spec states_for_step(StateOfMotion, float, Boolean) :: [StateOfMotion]
#  If intermediate states are being recorded AND the current displacement is less than or equal to to obstacle offset,
#  returns a list containing the current state of motion. Otherwise, returns an empty list.
  defp states_for_step(%StateOfMotion{} = state, sigma, record_states) do
    if state.x <= sigma and record_states do
      [state]
    else
      []
    end
  end

  @spec find_next_impact(StateOfMotion, ImpactPoint, EvolutionCoefficients, float, Boolean, float, float) :: [StateOfMotion]
#  For a given impact point and current state of motion, returns a list containing the state of motion corresponding to
#  the next impact. Optionally, the returned list will also contain the states corresponding to the intermediate time
#  steps.  The current state of motion is needed because the function is recursive.
  defp find_next_impact(%StateOfMotion{} = state, %ImpactPoint{} = _previous_impact, %EvolutionCoefficients{} = _coeffs,
         _sigma, _record_states, step_size, limit) when abs(step_size) < limit do
    # Termination criterion: return the state of motion corresponding to the next impact

    [state]
  end

  defp find_next_impact(%StateOfMotion{} = state, %ImpactPoint{} = previous_impact, %EvolutionCoefficients{} = coeffs,
         sigma, record_states, step_size, limit) do

    # Record current state if required
    states = states_for_step(state, sigma, record_states)

    # Update step size if necessary. When we are close to the impact, this implements the bisection algorithm which
    # finds the impact time
    step_size = new_step_size(step_size, state.x, sigma)

    # Get state at new time
    new_time = state.t + step_size
    new_state = motion_at_time(new_time, previous_impact, coeffs)

    # Recurse
    states ++ find_next_impact(new_state, previous_impact, coeffs, sigma, states, step_size, limit)
  end

  @doc """
  Where appropriate, refines the step size and reverses its direction. This effectively implements the bisection
  algorithm which seeks the time of the next impact
  """

  @spec new_step_size(float, float, float) :: float
  def new_step_size(step_size, x, sigma) when x <= sigma and step_size < 0 do
    # If we get here then previous displacement was above the offset, so continue to apply bisection algorithm
    -0.5 * step_size
  end

  def new_step_size(step_size, x, sigma) when x > sigma and step_size > 0 do
    # Displacement is above offset so apply bisection algorithm to seek impact time
    -0.5 * step_size
  end

  def new_step_size(step_size, _x, _sigma) do
    # Default behaviour: do nothing
    step_size
  end

  @doc """
  Generates a sequence of impacts from a specified starting impact

  `:start_impact`: the initial impact
  `:params`: the parameters governing the system behaviour
  `:num_iterations`: the number of impacts to compute

  Returns a list of `:num_iterations` impacts

  ## Example

  iex> initial_point = %ImpactPoint{phi: 0.5, v: 0.5}
  %ImpactPoint{phi: 0.5, v: 0.5}
  iex> params = %SystemParameters{omega: 2.8, r: 0.8, sigma: 0}
  %SystemParameters{omega: 2.8, r: 0.8, sigma: 0}
  iex> num_iterations = 10
  10
  iex> MotionBetweenImpacts.iterate_impacts(initial_point, params, num_iterations)
  [
    %ImpactPoint{phi: 0.5, v: 0.5},
    %ImpactPoint{phi: 1.258348997435864, v: 0.6396580088658008},
    %ImpactPoint{phi: 2.1791979948717275, v: 0.28209493346812553},
    %ImpactPoint{phi: 0.4187969923075898, v: 0.17606866202605073},
    %ImpactPoint{phi: 1.1412084897434536, v: 0.47836908299234254},
    %ImpactPoint{phi: 1.343307487179318, v: 0.1327150301794905},
    %ImpactPoint{phi: 0.3375939846151814, v: 0.4872891560716187},
    %ImpactPoint{phi: 1.1506304820510453, v: 0.6790838645307236},
    %ImpactPoint{phi: 1.9699169794869098, v: 0.23611127091193596},
    %ImpactPoint{phi: 0.1423284769227724, v: 0.20346731205860913}
  ]

  """

  @spec iterate_impacts(ImpactPoint, SystemParameters, integer) :: [ImpactPoint]
  def iterate_impacts(%ImpactPoint{} = start_impact, %SystemParameters{} = params, num_iterations \\ 1000) do
    stream = Stream.unfold(start_impact, &{&1, elem(next_impact(&1, params),0)})
    Enum.take(stream, num_iterations)
  end

end
