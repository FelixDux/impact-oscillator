defmodule ImpactPoint do
  @moduledoc """
  Struct for points on the impact surface
  """

  @doc """
  Each impact is uniquely specified by two parameters:

  `:phi`: the phase (time modulo and scaled by the forcing period) at which the impact occurs
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

  @spec point_to_list(%ImpactPoint{}) :: [number()]
  def point_to_list(%ImpactPoint{} = point) do
    [point.phi, point.v]
  end

  @doc """
  Initialises from a phase and a velocity. The time is set to the phase. 
  """

  @spec derive(number(), number()) :: %ImpactPoint{}
  def derive(phi, v) do
    %ImpactPoint{phi: phi, v: v, t: phi}
  end
end

defimpl String.Chars, for: ImpactPoint do
  def to_string(point) do
    "(#{point.phi}, #{point.v})"
  end
end

defimpl InputValidator, for: ImpactPoint do
  def validate(point) do
    point
    |> Map.to_list()
    |> Enum.reduce(point, fn {k, v}, acc ->
      cond do
        k == :__struct__ ->
          acc

        k == "__struct__" ->
          acc

        is_integer(v) ->
          acc

        is_float(v) ->
          acc

        true ->
          "Parameter #{k} must be numeric"
          |> (fn message ->
                case acc do
                  {:error, old_message} -> {:error, "#{old_message},\n#{message}"}
                  _ -> {:error, message}
                end
              end).()
      end
    end)
  end
end
