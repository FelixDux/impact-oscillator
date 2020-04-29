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

      "exit" -> finish()

      _ -> (fn -> help("Unrecognised command: #{&1}") end).()
    end).()
  end

  defp finish() do
    IO.puts("Goodbye")
  end

  defp get_command() do
    IO.gets(@prompt)  |> String.trim
  end

  defp help(prefix \\ "") do
    IO.puts(prefix)

    IO.puts("help:\tthis help\n")

    ActionMap.list_actions() |> Enum.map(fn {action, description} ->
      IO.puts("#{action}: #{description}")
    end)

    IO.puts("exit:\tclose the console\n")

    run()
  end

end
