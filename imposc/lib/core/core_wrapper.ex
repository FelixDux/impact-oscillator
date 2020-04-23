defmodule CoreWrapper do
  @moduledoc """
  Core wrapper: accepts (JSON-compatible) nested collections as input and interprets them into core function calls. 
  
  """

  def json_from_input() do
    IO.read(:all) |> JSON.decode
  end

  def json_to_output(data) do
    data |> JSON.encode! |> IO.puts
  end

  def process(input) do
    case input do
      {:ok, _} -> input |> elem(1) |> process

      [_|_] -> input |> Stream.map(&process(&1))

      _ -> input
    end
  end

  def process_input() do
    json_from_input() |> process |> json_to_output
  end
end
