
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

    period = ForcingPhase.forcing_period(parameters.omega)

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
                                                    ForcingPhase.modulo(phi, sticking_region.period), sticking_region)

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
    %StateOfMotion{t: ForcingPhase.forward_to_phase(t, sticking_region.phi_out, sticking_region.period),
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
