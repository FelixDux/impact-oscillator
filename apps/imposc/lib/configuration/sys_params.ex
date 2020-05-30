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

defimpl String.Chars, for: SystemParameters do
  def to_string(parameters) do
    "omega = #{parameters.omega}, sigma = #{parameters.sigma}, r = #{parameters.r}"
  end
end

defimpl InputValidator, for: SystemParameters do
  def validate(parameters) do
    parameters
    |> Map.to_list()
    |> Enum.reduce(parameters, fn {k, v}, acc ->
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
