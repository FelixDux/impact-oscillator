defmodule CoreWrapper do
  @moduledoc """
  Core wrapper: accepts (JSON-compatible) nested collections as input and interprets them into core function calls. 

  """

  @doc """
  Initialises a struct from a `:Map` whose keys are strings.

  Taken from https://groups.google.com/forum/#!msg/elixir-lang-talk/6geXOLUeIpI/L9einu4EEAAJ
  """
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

  defp from_attrs(kind, attrs) when Integer == kind and is_integer(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) when Float == kind and is_float(attrs) do
    attrs
  end

  defp from_attrs(kind, attrs) do
    case kind.module_info() |> Keyword.fetch!(:module) do
      ImpactPoint ->
        attrs
        |> (&to_struct(ImpactPoint, &1)).()
        |> (&%ImpactPoint{phi: &1.phi, v: &1.v, t: &1.phi}).()

      SystemParameters ->
        attrs |> (&to_struct(SystemParameters, &1)).()

      _ ->
        nil
    end
  end

  def from_args(kind, args, key) do
    case Map.fetch(args, key) do
      {:ok, attrs} ->
        attrs |> (&from_attrs(kind, &1)).()

      :error ->
        {:error, "Missing arguments for \"#{key}\""}
    end
  end

  def scatter(args) do
    args
    |> (&ImpactMap.chart_impacts(
          from_args(ImpactPoint, &1, "initial_point"),
          from_args(SystemParameters, &1, "params"),
          from_args(Integer, &1, "num_iterations")
        )).()
  end

  def ellipse(args) do
    args
    |> (&Curves.sigma_ellipse(
          from_args(Integer, &1, "n"),
          from_args(Float, &1, "omega"),
          from_args(Float, &1, "r"),
          from_args(Integer, &1, "num_points")
        )).()
  end

  def timeseries(args) do
    args
    |> (&TimeSeries.time_series(
          from_args(ImpactPoint, &1, "start_impact"),
          from_args(SystemParameters, &1, "params")
        )).()
  end

  defp execute_action(input) do
    Task.async( fn -> 
    case input do
      {:error, _} -> input
      %{"action" => "scatter", "args" => args} -> args |> scatter
      %{"action" => "ellipse", "args" => args} -> args |> ellipse
      %{"action" => "timeseries", "args" => args} -> args |> timeseries
      # _ -> IO.inspect(input) 

      _ -> {:error, "Could not retrieve action from JSON input"}
    end end) 
  end

  def json_from_input(input) do
    input |> JSON.decode
  end

  def json_to_output(data) do
    data |> JSON.encode!
  end

  def process(input) do
    case input do
      {:ok, _} -> input |> elem(1) |> process
      [_ | _] -> input |> Enum.map(&process(&1))
      _ -> input |> execute_action |> Task.await
    end
  end

  def process_input_string(input) do
    input |> json_from_input |> process |> json_to_output
  end

  def process_input() do
    IO.read(:all) |> process_input_string |> IO.puts
  end
end
