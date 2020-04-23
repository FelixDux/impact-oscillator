defmodule CoreWrapper do
  @moduledoc """
  Core wrapper: accepts (JSON-compatible) nested collections as input and interprets them into core function calls. 
  
  """

  def json_from_input(input) do
    input |> JSON.decode
  end

  def json_to_output(data) do
    data |> JSON.encode! 
  end

  def process(input) do
    case input do
      {:ok, _} -> input |> elem(1) |> process

      [_|_] -> input |> Enum.map(&process(&1))

      _ -> input
    end
  end

  def process_input_string(input) do
    input |> json_from_input |> process |> json_to_output
  end

  def process_input() do
    IO.read(:all) |> process_input_string |> IO.puts
  end
end
