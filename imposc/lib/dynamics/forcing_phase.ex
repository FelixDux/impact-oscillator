defmodule ForcingPhase do
  @moduledoc """
  Functions for converting between time and phase modulo a forcing frequency.
  """

  @doc """
  Returns the fractional part of a number()ing point number
  """

  @spec frac_part(number()) :: number()
  def frac_part(x) do
    x - trunc(x)
  end

  @doc """
  Returns the remainder of `:x` divided by `:y` - like `Kernel.rem` but for number()s
  """

  @spec modulo(number(), number()) :: number()
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
    x - trunc(x / y) * y
  end

  @doc """
  For a given forcing frequency `:omega` returns the the forcing period
  """

  @spec forcing_period(number()) :: {atom(), number()}
  def forcing_period(omega) do
    cond do
      omega <= 0 -> {:error, "Forcing frequency must be positive"}
      true -> {:ok, 2.0 * :math.pi() / omega}
    end
  end

  @doc """
  For a given time `:t` and forcing frequency `:omega` returns the phase 
  relative to the forcing period and optionally scaled by the forcing 
  period so that it ranges from 0 to 1
  """

  @spec phi(number(), number(), boolean()) :: number()
  def phi(t, omega, scaled \\ true) do
    forcing_period(omega)
    |> (&if(elem(&1, 0) == :ok,
          do:
            elem(&1, 1)
            |> (fn period -> modulo(t, period) / if(scaled, do: period, else: 1) end).(),
          else: nil
        )).()
  end

  @doc """
  Returns the lowest time greater than or equal to time `:t` for which the phase relative to `:period` is `:phi`
  """

  @spec forward_to_phase(number(), number(), number()) :: number()
  def forward_to_phase(t, phi, period) do
    phase_difference = period * phi - modulo(t, period)

    result =
      cond do
        phase_difference >= 0 -> t + phase_difference
        true -> t + period + phase_difference
      end

    # Check for rounding errors - new phase should equal old. We particularly don't want it to be slightly less, as this
    # could trap us in the sticking region
    new_phi = modulo(result / period, 1)

    delta_phi = phi - new_phi

    cond do
      delta_phi > 0 -> result + delta_phi * period
      true -> result
    end
  end

  @doc """
  For a forcing frequency `:omega` returns the coefficient of the forcing term in the equation for
  the displacement between impacts
  """

  @spec gamma(number()) :: number()
  def gamma(omega) when omega in [1, -1] do
    1
  end

  def gamma(omega) do
    1.0 / (1.0 - :math.pow(omega, 2))
  end
end
