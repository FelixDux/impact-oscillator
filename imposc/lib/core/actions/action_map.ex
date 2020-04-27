defmodule ActionMap do
  @moduledoc """
  Maps action names to names of modules which implement the `:Action` behaviour
  """
  
  @actions %{
    "scatter" => "ScatterAction",
    "ellipse" => "EllipseAction",
    "timeseries" => "TimeSeriesAction"
  }

  def execute(action, args) do
    case Map.fetch(@actions, action) do
      :error -> {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} -> module_name |> (&apply(String.to_existing_atom("Elixir.#{&1}"), :execute, [args])).()
    end
  end
end
