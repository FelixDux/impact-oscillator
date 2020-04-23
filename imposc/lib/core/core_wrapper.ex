defmodule CoreWrapper do
  @moduledoc """
  Core wrapper: accepts (JSON-compatible) nested collections as input and interprets them into core function calls. 

  """

  @function_map %{
    scatter: CoreWrapper.scatter/1
  }

  def scatter(args) do
    ImpactMap.chart_impacts(
      struct(ImpactPoint, Map.fetch!(args, :initial_point)), 
      struct(SystemParameters, Map.fetch!(args, :params))) 
  end

  defp get_function(action) do
    Map.fetch!(@function_map, action)
  end


  defp execute_function(input) do
    f = input |> Map.fetch!(:action) |> get_function

    input |> Map.fetch!(:args) |> f
  end

  def json_from_input(input) do
    input |> JSON.decode()
  end

  def json_to_output(data) do
    data |> JSON.encode!()
  end

  def process(input) do
    case input do
      {:ok, _} -> input |> elem(1) |> process
      [_ | _] -> input |> Enum.map(&process(&1))
      _ -> input |> execute_function
    end
  end

  def process_input_string(input) do
    input |> json_from_input |> process |> json_to_output
  end

  def process_input() do
    IO.read(:all) |> process_input_string |> IO.puts()
  end
end
