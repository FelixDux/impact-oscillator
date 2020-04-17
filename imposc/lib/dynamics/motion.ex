

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

  @spec next_impact(ImpactPoint, SystemParameters, (integer -> (float -> any)), Boolean, number, number) :: point_with_states
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