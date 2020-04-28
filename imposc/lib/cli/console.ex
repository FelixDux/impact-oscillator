defmodule Console do
  @moduledoc """
  Implements a console interface.
  """

  @prompt "imposc> "

  @doc """
  Runs the console, prompting for commands from standard input
  """
  def run() do
    get_command() |> (& case &1 do
      "help" -> help()

      _ -> (fn -> help("Unrecognised command: #{&1}")
          run() end).()
    end).()
  end

  defp get_command() do
    IO.gets(@prompt)  |> String.trim
  end

  defp help(prefix \\ "") do
    IO.puts(prefix)

    IO.puts("help:\tthis help")
  end

end
