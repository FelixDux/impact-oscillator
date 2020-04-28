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

  @spec point_from_state(%StateOfMotion{}, number()) :: %ImpactPoint{}
  def point_from_state(%StateOfMotion{} = state, omega) do
    %ImpactPoint{phi: ForcingPhase.phi(state.t, omega), v: state.v, t: state.t}
  end
end
