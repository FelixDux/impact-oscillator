defmodule ImposcConstants do

  @moduledoc """
  Tolerances for floating point comparisons
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
end

