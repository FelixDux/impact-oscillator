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
  For a given forcing frequency `:omega` returns the the forcing period
  """

  @spec forcing_period(float) :: float
  def forcing_period(omega) do
    case omega do
      0 -> nil  # TODO use {:ok, result}/:error pattern AND handle negative case
      _ -> 2.0*:math.pi/omega
    end
  end

  @doc """
  For a given time `:t` and forcing frequency `:omega` returns the phase relative to the forcing period
  """

  @spec phi(float, float) :: float
  def phi(t, omega) do
    modulo(t,forcing_period(omega))
  end

  @doc """
  Returns the lowest time greater than or equal to time `:t` for which the phase relative to `:period` is `:phi`
  """

  @spec forward_to_phase(float, float, float)::float
  def forward_to_phase(t, phi, period) do
    phase_difference = phi - modulo(t, period)

    result = cond do
      phase_difference >= 0 -> t + phase_difference

      true -> t + period + phase_difference
    end

    # Check for rounding errors - new phase should equal old. We particularly don't want it to be slightly less, as this
    # could trap us in the sticking region
    new_phi = modulo(result, period)

    delta_phi = phi - new_phi

    cond do
      delta_phi > 0 -> result + delta_phi

      true -> result
    end
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
    quote do: 0.0001
  end

  defmacro const_smallish do
    quote do: 0.05
  end

  defmacro const_tiny do
    quote do: 0.000001
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

  In addition, we also record the actual time `:t`.

  Because `:phi` is periodic and `:v` non-negative, the surface on which impacts are
  defined is a half-cylinder. Whether a zero-velocity impact is physically meaningful
  depends on the value of `:phi` and on `sigma` the offset of the obstacle from the
  centre of motion.
  """

  defstruct phi: 0, v: 0, t: 0

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
    %ImpactPoint{phi: ImposcUtils.phi(state.t, omega), v: state.v, t: state.t}
  end
end

defmodule StickingRegion do
  @moduledoc """
  The interval of phases over which  zero-velocity impacts have non-negative acceleration.

  For such impacts, the forcing holds the mass against the obstacle until the acceleration changes sign. This
  phenomenon can only occur if the obstacle offset is < 1.
  """
  @doc """
  `:phi_in`: the minimum phase (modulo the forcing period) for which zero-velocity impacts have non-negative acceleration
  `:phi_out`: the maximum phase (modulo the forcing period) for which zero-velocity impacts have non-negative acceleration
  `:period`: the forcing period

  The acceleration is actually zero for both `:phi_in` and `:phi_out` but its rate of change is positive for the former
  and negative for the latter.
  """

  defstruct phi_in: 0, phi_out: 0, period: 1

  @doc """
  Derive a `:StickingRegion` from `:SystemParameters`
  """

  @spec derive(SystemParameters) :: StickingRegion
  def derive(%SystemParameters{} = parameters) do

    period = ImposcUtils.forcing_period(parameters.omega)

    cond do
      # No sticking region
      parameters.sigma > 1 -> %StickingRegion{phi_in: nil, phi_out: nil, period: period}

      # Sticking region is a single point
      parameters.sigma == 1 -> %StickingRegion{phi_in: 0, phi_out: 0, period: period}


      # Sticking region is whole phi-axis
      parameters.sigma <= -1 -> %StickingRegion{phi_in: period, phi_out: 0, period: period}

      # Zero velocity and zero acceleration condition
      true -> :math.acos(parameters.sigma) |>
            (fn(angle) ->
              cond do

                # Condition on rate of change of acceleration
                :math.sin(angle) < 0 -> %StickingRegion{phi_in: angle/parameters.omega,
                                          phi_out: (2*:math.pi - angle)/parameters.omega,
                                          period: period}
                true ->  %StickingRegion{phi_out: angle/parameters.omega, phi_in: (2*:math.pi - angle)/parameters.omega,
                           period: period}

              end
            end).()
    end
  end

  @doc """
  Check if the phase `:phi` is in the `:sticking_region`
  """

  @spec is_sticking?(float, StickingRegion) :: Boolean
  def is_sticking?(phi, %StickingRegion{} = sticking_region) do
    cond do
      # No sticking region
      sticking_region.phi_out == nil -> false

      # Recurse if phi not expressed as a phase
      phi < 0 or phi >= sticking_region.period -> StickingRegion.is_sticking?(
                                                    ImposcUtils.modulo(phi, sticking_region.period), sticking_region)

      # phi_out is always <= phi_in, treated as real numbers, but as phases they lie on a circle, so it still makes
      # sense to check for containment inside the closed interval [phi_in, phi_out) by reasoning that its complement
      # is [phi_out, phi_in)
      phi >= sticking_region.phi_out and phi < sticking_region.phi_in -> false

      # Not inside the complement, so inside the sticking region
      true -> true
    end
  end

  def is_sticking_impact?(%ImpactPoint{} = point, %StickingRegion{} = sticking_region) do
    cond do
      point.v > 0 -> false

      true -> StickingRegion.is_sticking?(point.phi, sticking_region)
    end
  end

  @doc """
  For a given impact time `:t` and obstacle offset `:sigma`, returns a `:StateOfMotion` corresponding to the point
  when the mass unsticks, according to the `:sticking_region`.

  **Precondition** `:t` is the time of a sticking impact (i.e. the corresponding phase is inside the
  `:sticking_region`) and the associated velocity is zero
  """

  @spec next_impact_state(float, float, StickingRegion) :: StateOfMotion
  def next_impact_state(t, sigma, %StickingRegion{} = sticking_region) do
    %StateOfMotion{t: ImposcUtils.forward_to_phase(t, sticking_region.phi_out, sticking_region.period),
                x: sigma, v: 0}
  end

  @spec state_if_sticking(StateOfMotion, StickingRegion) :: StateOfMotion
  def state_if_sticking(%StateOfMotion{} = state, %StickingRegion{} = sticking_region) do
    if is_sticking?(state.t, sticking_region) do
      state
    else
      nil
    end
  end
end

defmodule Chatter do
  @moduledoc """
  Functions and data for numerically approximating 'chatter'.

  'Chatter' is when an infinite sequence of impacts accumulates in a finite time on a 'sticking' impact. It is
  the analogue in this system to a real-world situation in which the mass judders against the stop. To handle it
  numerically it is necessary to detect when it is happening and then extrapolate forward to the accumulation point.
  """

  @spec low_velocity_acceleration(float, float, float)::float
  defp low_velocity_acceleration(t, x, omega) do
    # Approximates the acceleration at low velocity
    :math.cos(omega * t) - x
  end

  @doc """
  Returns the `:StateOfMotion` corresponding to the limit of a sequence of chatter impacts.

  `:state`: the `:StateOfMotion` corresponding to a starting impact
  `:parameters`: system parameters for the oscillator

  **Precondition** `:state` is assumed to correspond to a low velocity impact (i.e. `:state.x` == `:parameters.sigma`
  and `:state.v` small) but this is not checked. If these conditions are not met, the return value will be meaningless.
  """

  @spec accumulation_state(StateOfMotion, SystemParameters) :: StateOfMotion
  def accumulation_state(%StateOfMotion{} = state, %SystemParameters{} = parameters) do
    g = low_velocity_acceleration(state.t, parameters.sigma, parameters.omega)

    case g do
      0 -> StickingRegion.next_impact_state(state.t, parameters.sigma,StickingRegion.derive(parameters))

      # TODO: handle case r=0
      _ -> %StateOfMotion{t: state.t - 2 * state.v / g / (1 - parameters.r), x: parameters.sigma, v: 0}
    end
  end

  @doc """
  The number of successive low velocity impacts after which the test for chatter will be applied.

  TODO: make configurable
  """

  defmacro const_low_v_count_threshold do
    quote do: 10
  end

  def check_low_v(counter \\0) do

    import ImposcUtils
    fn v -> if v != 0 && v < ImposcUtils.const_smallish() do
              if counter < const_low_v_count_threshold() do
                {false, check_low_v(counter+1)}
              else
                {true, check_low_v(0)}
              end
            else
              {false, check_low_v(0)}
            end
    end
  end
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
  `:sticking_region`: the range of phases for which zero-velocity impacts stick
  """

  defstruct omega: 2, gamma: -1/3.0, cos_coeff: 1, sin_coeff: 0, sticking_region: %StickingRegion{}

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
    result = %{result | sticking_region: StickingRegion.derive(parameters)}
    result
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

  @type point_with_states :: {ImpactPoint, [StateOfMotion], Chatter.check_low_v}

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
    lambda = t - previous_impact.t

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

#  @spec next_impact(ImpactPoint, SystemParameters, Boolean, number, number) :: point_with_states
  def next_impact(%ImpactPoint{} = previous_impact, %SystemParameters{} = parameters, chatter_counter
      \\ Chatter.check_low_v(), record_states \\ false, step_size \\ 0.1, limit \\ 0.000001) do

    coeffs = EvolutionCoefficients.derive(parameters, previous_impact)
    start_state = %StateOfMotion{t: previous_impact.t, x: parameters.sigma, v: -parameters.r * previous_impact.v}

    # Check for chatter
    check_chatter = fn state, parameters, sticking_region -> Chatter.accumulation_state(state, parameters) |>
                                                               (&StickingRegion.state_if_sticking(&1, sticking_region)).() end

    {chatter_impact, new_counter} = chatter_counter.(previous_impact.v)

    chatter_result = chatter_impact && check_chatter.(start_state, parameters, coeffs.sticking_region)

    states = if chatter_result  do
      states_for_step(start_state, parameters.sigma, record_states) ++ [chatter_result]
    else
      find_next_impact(start_state, previous_impact, coeffs, parameters, record_states, step_size, limit)
    end

    {StateOfMotion.point_from_state(Enum.at(states, -1), parameters.omega), states, new_counter}
  end

  @spec states_for_step(StateOfMotion, float, Boolean) :: [StateOfMotion]
#  If intermediate states are being recorded AND the current displacement is less than or equal to the obstacle offset,
#  returns a list containing the current state of motion. Otherwise, returns an empty list.
  defp states_for_step(%StateOfMotion{} = state, sigma, record_states) do
    if state.x <= sigma and record_states do
      [state]
    else
      []
    end
  end

  @spec find_next_impact(StateOfMotion, ImpactPoint, EvolutionCoefficients, SystemParameters, Boolean, float, float) :: [StateOfMotion]
#  For a given impact point and current state of motion, returns a list containing the state of motion corresponding to
#  the next impact. Optionally, the returned list will also contain the states corresponding to the intermediate time
#  steps.  The current state of motion is needed because the function is recursive.
  defp find_next_impact(%StateOfMotion{} = state, %ImpactPoint{} = _previous_impact, %EvolutionCoefficients{} = _coeffs,
         %SystemParameters{} = _parameters, _record_states, step_size, limit) when abs(step_size) < limit do
    # Termination criterion: return the state of motion corresponding to the next impact

    [state]
  end

  defp find_next_impact(%StateOfMotion{} = state, %ImpactPoint{} = previous_impact, %EvolutionCoefficients{} = coeffs,
         %SystemParameters{} = parameters, record_states, step_size, limit) do

    # Record current state if required
    states = states_for_step(state, parameters.sigma, record_states)

    # Check for sticking
    if StickingRegion.is_sticking_impact?(previous_impact, coeffs.sticking_region) do
      states ++ [StickingRegion.next_impact_state(state.t, state.x, coeffs.sticking_region)]
    else
      # Update step size if necessary. When we are close to the impact, this implements the bisection algorithm which
      # finds the impact time
      step_size = new_step_size(step_size, state.t - previous_impact.t, state.x, parameters.sigma)

      # Get state at new time
      new_time = state.t + step_size

      new_state = motion_at_time(new_time, previous_impact, coeffs)

      # Recurse
      states ++ find_next_impact(new_state, previous_impact, coeffs, parameters, states, step_size, limit)
    end
  end

  @doc """
  Where appropriate, refines the step size and reverses its direction. This effectively implements the bisection
  algorithm which seeks the time of the next impact
  """

  @spec new_step_size(float, float, float, float) :: float
  def new_step_size(step_size, _time_diff, x, sigma) when x <= sigma and step_size < 0 do
    # If we get here then previous displacement was above the offset, so continue to apply bisection algorithm
    -0.5 * step_size
  end

  def new_step_size(step_size, time_diff, x, sigma) when x > sigma and step_size > 0 do
    # Displacement is above offset so apply bisection algorithm to seek impact time
    # BUT don't step farther back than the previous impact
    -0.5 * min(step_size, time_diff)
  end

  def new_step_size(step_size, time_diff, _x, _sigma) when step_size <= -time_diff do
    # Continue search in same direction
    # BUT don't step farther back than the previous impact
    -0.5 * time_diff
  end

  def new_step_size(step_size, _time_diff, _x, _sigma) do
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

  @spec iterate_impacts(ImpactPoint, SystemParameters, integer, Boolean) :: [ImpactPoint]
  def iterate_impacts(%ImpactPoint{} = start_impact, %SystemParameters{} = params, num_iterations \\ 1000,
        record_states \\ false) do
    chatter_counter = Chatter.check_low_v()
    stream = Stream.unfold({start_impact, [], chatter_counter}, &{&1, next_impact(elem(&1, 0), params, elem(&1, 2),
      record_states)})
    Enum.take(stream, num_iterations) |> (&{Enum.reduce(&1, [], fn x, acc -> acc ++ [elem(x, 0)] end),
      Enum.reduce(&1, [], fn x, acc -> acc ++ elem(x, 1) end)}).()
  end

end
