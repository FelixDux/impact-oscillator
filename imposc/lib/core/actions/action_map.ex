defmodule ActionMap do
  @moduledoc """
  Maps action names to names of modules which implement the `:Action` behaviour
  """

  @actions %{
    "multiplot" => "MultiplotAction",
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

  def module_for_action(action) do
    with :error <- Map.fetch(@actions, action) do
      {:error, "Unrecognised action \"#{action}\""}
    end
  end

  def get_module(module_name) do
    module_name |> (&String.to_existing_atom("Elixir.#{&1}")).()
  end

  @spec execute(iodata(), map() | [map()], map()) :: atom() | {atom(), iodata()}
  def execute(action, args, options) do
    with {:ok, module_name} <- module_for_action(action), module = module_name |> get_module do
      if is_list(args) and false == run_for_module(module, :expects_list?, []) do
        args |> Enum.map(&execute(action, &1, options))
      else
        with {:ok, _} <-
               module |> (&Action.validate(&1, args, options)).(),
             do: module |> (&run_for_module(&1, :execute, [args, options])).()
      end
    end
  end

  defp run_for_module(module, function_name, arg_list) when is_binary(module) do
    module |> get_module |> run_for_module(function_name, arg_list)
  end

  defp run_for_module(module, function_name, arg_list) do
    module |> apply(function_name, arg_list)
  end

  @spec requirements(iodata()) :: map() | {atom(), iodata()}
  def requirements(action) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        module_name |> (&run_for_module(&1, :requirements, [])).()
    end
  end

  @spec expected_options(iodata()) :: map() | {atom(), iodata()}
  def expected_options(action) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        module_name |> (&run_for_module(&1, :expected_options, [])).()
    end
  end

  @spec description(iodata()) :: iodata() | {atom(), iodata()}
  def description(action) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        module_name |> (&run_for_module(&1, :description, [])).()
    end
  end

  @spec action_info(iodata()) :: map() | {atom(), iodata()}
  def action_info(action) do
    case Map.fetch(@actions, action) do
      :error ->
        {:error, "Unrecognised action \"#{action}\""}

      {:ok, module_name} ->
        [:requirements, :description, :expected_options]
        |> Enum.map(&{&1, run_for_module(module_name, &1, [])})
        |> (&([{:action, action}] ++ &1)).()
        |> Map.new()
    end
  end
end
