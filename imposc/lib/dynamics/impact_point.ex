defmodule ImpactPoint do
  @moduledoc """
  Struct for points on the impact surface
  """

  @doc """
  Each impact is uniquely specified by two parameters:

  `:phi`: the phase (time modulo the forcing period) at which the impact occurs
  `:v`: the velocity of the impact, which cannot be negative

  In addition, we also record the actual time `:t`.

  Because `:phi` is periodic and `:v` non-negative, the surface on which impacts are
  defined is a half-cylinder. Whether a zero-velocity impact is physically meaningful
  depends on the value of `:phi` and on `sigma` the offset of the obstacle from the
  centre of motion.
  """

  defstruct phi: 0, v: 0, t: 0

  @doc """
  Converts the struct to a list [`:phi`, `:v`].
  """

  @spec point_to_list(ImpactPoint) :: [float]
  def point_to_list(%ImpactPoint{} = point) do
    [point.phi, point.v]
  end
end
