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
end
