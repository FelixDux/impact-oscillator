defmodule ActionMap do
  @moduledoc """
  Maps action names to names of modules which implement the `:Action` behaviour
  """

  @actions %{
    "scatter" => "ScatterAction",
    "ellipse" => "EllipseAction",
    "timeseries" => "TimeSeriesAction"
  }

  @doc """
  Lists the available actions with their descriptions.
  """
  @spec list_actions() :: [{iodata(), iodata()}, ...]
  def list_actions() do
    Enum.map(Map.keys(@actions), fn action -> {action, description(action)} end)
  end

  @spec execute(iodata(), map(), map()) :: atom() | {atom(), iodata()}
  def execute(action, args, options) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        module_name
        |> (&apply(String.to_existing_atom("Elixir.#{&1}"), :execute, [args, options])).()
    end
  end

  @spec requirements(iodata()) :: map() | {atom(), iodata()}
  def requirements(action) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        module_name |> (&apply(String.to_existing_atom("Elixir.#{&1}"), :requirements, [])).()
    end
  end

  @spec expected_options(iodata()) :: map() | {atom(), iodata()}
  def expected_options(action) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        module_name |> (&apply(String.to_existing_atom("Elixir.#{&1}"), :expected_options, [])).()
    end
  end

  @spec description(iodata()) :: iodata() | {atom(), iodata()}
  def description(action) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        module_name |> (&apply(String.to_existing_atom("Elixir.#{&1}"), :description, [])).()
    end
  end
end
