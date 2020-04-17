defmodule ForcingPhase do
  @moduledoc """
  Functions for converting between time and phase modulo a forcing frequency.
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
end



