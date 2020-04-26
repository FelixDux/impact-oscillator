defmodule CoreWrapper do
  @moduledoc """
  Core wrapper: accepts (JSON-compatible) nested collections as input and interprets them into core function calls. 

  """

  @doc """
  Initialises a struct of type `:kind` from a `:Map` whose keys are strings.

  Taken from https://groups.google.com/forum/#!msg/elixir-lang-talk/6geXOLUeIpI/L9einu4EEAAJ
  """
  @spec to_struct(module(), map()) :: struct()
  def to_struct(kind, attrs) do
    kind
    |> struct
    |> (fn struct ->
          Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
            case Map.fetch(attrs, Atom.to_string(k)) do
              {:ok, v} -> %{acc | k => v}
              :error -> acc
            end
          end)
        end).()
  end

  # Extracts an input parameter of type `:kind` from `:attrs`. If `:attrs`
  # is a number we just return it, if it is a `:Map` we convert it to a 
  # struct type sepcified by `:kind`.
  defp from_attrs(kind, attrs) when Integer == kind and is_integer(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) when Float == kind and is_float(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) do
    # Work out which struct type is needed and initialise it appropriately.
    case kind.module_info() |> Keyword.fetch(:module) do
      {:ok, module_type} ->
        case module_type do
          ImpactPoint ->
            attrs
            |> (&to_struct(ImpactPoint, &1)).()
            # We just expect the phase and velocity from the input and initialise
            # the time to the phase
            |> (&%ImpactPoint{phi: &1.phi, v: &1.v, t: &1.phi}).()

          SystemParameters ->
            attrs |> (&to_struct(SystemParameters, &1)).()

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  @doc """
  Extracts an input parameter of type `:kind` from `:args` using key `:key`.
  """
  @spec from_args(module(), map(), iodata()) :: nil | number() | {atom(), iodata()} | struct()
  def from_args(kind, args, key) do
    case Map.fetch(args, key) do
      {:ok, attrs} ->
        attrs |> (&from_attrs(kind, &1)).()

      :error ->
        {:error, "Missing arguments for \"#{key}\""}
    end
  end

  @doc """
  Generates a scatter plot using arguments initialised from `:args`.
  """
  @spec scatter(map()) :: nil | number() | {atom(), iodata()} | struct()
  def scatter(args) do
    args
    |> (&ImpactMap.chart_impacts(
          from_args(ImpactPoint, &1, "initial_point"),
          from_args(SystemParameters, &1, "params"),
          from_args(Integer, &1, "num_iterations")
        )).()
  end

  @doc """
  Generates a (1, n) orbit sigma response plot using arguments initialised from `:args`.
  """
  @spec ellipse(map()) :: nil | number() | {atom(), iodata()} | struct()
  def ellipse(args) do
    args
    |> (&Curves.sigma_ellipse(
          from_args(Integer, &1, "n"),
          from_args(Float, &1, "omega"),
          from_args(Float, &1, "r"),
          from_args(Integer, &1, "num_points")
        )).()
  end

  @doc """
  Generates a time-series plot using arguments initialised from `:args`.
  """
  @spec timeseries(map()) :: nil | number() | {atom(), iodata()} | struct()
  def timeseries(args) do
    args
    |> (&TimeSeries.time_series(
          from_args(ImpactPoint, &1, "start_impact"),
          from_args(SystemParameters, &1, "params")
        )).()
  end

  # Determines which kind of action is required by a JSON-derived `:Map`
  # of `:input` and returns an async-ed `:Task` to execute it.
  defp execute_action(input) do
    Task.async(fn ->
      case input do
        {:error, _} -> input
        %{"action" => "scatter", "args" => args} -> args |> scatter
        %{"action" => "ellipse", "args" => args} -> args |> ellipse
        %{"action" => "timeseries", "args" => args} -> args |> timeseries
        # _ -> IO.inspect(input) 

        _ -> {:error, "Could not retrieve action from JSON input"}
      end
    end)
  end

  def process(input) do
    case input do
      {:ok, _} -> input |> elem(1) |> process
      [_ | _] -> input |> Enum.map(&process(&1))
      _ -> input |> execute_action |> Task.await()
    end
  end

  def process_input_string(input) do
    input |> JSON.decode() |> process |> JSON.encode!()
  end

  def process_input() do
    IO.read(:all) |> process_input_string |> IO.puts()
  end
end
