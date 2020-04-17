
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

  @spec check_low_v(integer) :: {Boolean, (float -> any)}
  def check_low_v(counter \\0) do

    require ImposcConstants
    fn v -> if v != 0 && v < ImposcConstants.const_smallish() do
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