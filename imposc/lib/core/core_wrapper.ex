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

  def to_impact_point(args, key \\ "initial_point") do
    case Map.fetch(args, key) do
      {:ok, attrs} ->
        attrs
        |> (&to_struct(ImpactPoint, &1)).()
        |> (&%ImpactPoint{phi: &1.phi, v: &1.v, t: &1.phi}).()

      :error ->
        {:error, "Missing arguments for \"#{key}\""}
    end
  end

  def scatter(args) do
    ImpactMap.chart_impacts(
      to_impact_point(args),
      to_struct(SystemParameters, Map.fetch!(args, "params"))
    )
  end

  defp execute_action(input) do
    case input do
      {:error, _} -> input
      %{"action" => "scatter", "args" => args} -> args |> scatter
      # _ -> IO.inspect(input) 

      _ -> {:error, "Could not retrieve action from JSON input"}
    end
  end

  def json_from_input(input) do
    # |> IO.inspect
    input |> JSON.decode()
  end

  def json_to_output(data) do
    data |> JSON.encode!()
  end

  def process(input) do
    case input do
      {:ok, _} -> input |> elem(1) |> process
      [_ | _] -> input |> Enum.map(&process(&1))
      _ -> input |> execute_action
    end
  end

  def process_input_string(input) do
    input |> json_from_input |> process |> json_to_output
  end

  def process_input() do
    IO.read(:all) |> process_input_string |> IO.puts()
  end
end
