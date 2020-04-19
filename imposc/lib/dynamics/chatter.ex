defmodule Chatter do
  @moduledoc """
  Functions and data for numerically approximating 'chatter'.

  'Chatter' is when an infinite sequence of impacts accumulates in a finite time on a 'sticking' impact. It is
  the analogue in this system to a real-world situation in which the mass judders against the stop. To handle it
  numerically it is necessary to detect when it is happening and then extrapolate forward to the accumulation point.
  """

  @spec low_velocity_acceleration(float, float, float) :: float
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

  **Precondition** chatter cannot occur for `:parameters.r` >= 1. This will result in an error condition.
  """

  @spec accumulation_state(StateOfMotion, SystemParameters) :: {atom, StateOfMotion}
  def accumulation_state(%StateOfMotion{} = state, %SystemParameters{} = parameters) do
    g = low_velocity_acceleration(state.t, parameters.sigma, parameters.omega)

    cond do
      parameters.r >= 1 ->
        {:error, "Chatter cannot occur for coefficient of restitution >= 1"}

      parameters.r < 0 ->
        {:error, "Chatter cannot occur for coefficient of restitution < 1"}

      g < 0 ->
        {:error, "Chatter will not occur outside the sticking region"}

      g == 0 ->
        case StickingRegion.derive(parameters) do
          {:ok, region} ->
            {:ok,
             StickingRegion.next_impact_state(
               state.t,
               parameters.sigma,
               region
             )}

          other ->
            other
        end

      true ->
        {:ok,
         %StateOfMotion{
           t: state.t - 2 * state.v / g / (1 - parameters.r),
           x: parameters.sigma,
           v: 0
         }}
    end
  end

  @doc """
  The number of successive low velocity impacts after which the test for chatter will be applied.

  TODO: make configurable
  """

  defmacro const_low_v_count_threshold do
    quote do: 10
  end

  @doc """
  Counts successive low velocity impacts and flags when a threshold number have been reached.

  Used in detecting chatter.
  """

  @spec count_low_v(integer) :: {Boolean, (float -> any)}
  def count_low_v(counter \\ 0) do
    require ImposcConstants

    fn v ->
      if v != 0 && v < ImposcConstants.const_smallish() do
        if counter < const_low_v_count_threshold() do
          {false, count_low_v(counter + 1)}
        else
          {true, count_low_v(0)}
        end
      else
        {false, count_low_v(0)}
      end
    end
  end
end
