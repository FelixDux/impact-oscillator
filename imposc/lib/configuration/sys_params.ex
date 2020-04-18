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
