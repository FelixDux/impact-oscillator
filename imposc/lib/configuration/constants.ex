defmodule ImposcConstants do
  @moduledoc """
  Tolerances for floating point comparisons
  """

  @const_small 0.0001

  def const_small, do: @const_small

  @const_smallish 0.05

  def const_smallish, do: @const_smallish

  @const_tiny 0.000001

  def const_tiny, do: @const_tiny
end
