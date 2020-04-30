defmodule Console do
  @moduledoc """
  Implements a console interface.
  """

  @prompt "imposc> "

  @doc """
  Runs the console, prompting for commands from standard input
  """
  def run() do
    get_command()
    |> (&(case &1 do
            "help" -> help()
            "exit" -> finish()
            _ -> process_command(&1)
          end)).()
  end

  defp process_command(command) do
    ActionMap.requirements(command)
    |> (&(case &1 do
            {:error, _} ->
              help("Unrecognised command: #{command}")

            template ->
              (fn ->
                 get_for_requirements(template)
                 |> (fn args -> %{"action" => command, "args" => args} end).()
                 |> CoreWrapper.process_decoded()
                 |> IO.puts()

                 # IO.inspect
                 run()
               end).()
          end)).()
  end

  defp get_for_requirements(requirements) do
    Map.keys(requirements)
    |> (fn names ->
          Enum.reduce(names, %{}, fn new_name, new_input ->
            get_input(new_input, new_name, requirements)
          end)
        end).()
  end

  defp marshall_numeric(input) do
    case input |> String.trim() |> Integer.parse() do
      {value, ""} -> value
      _ -> input |> String.trim() |> Float.parse() |> elem(0)
    end
  end

  defp get_input(input, name, template) do
    case Map.fetch!(template, name) do
      nil ->
        IO.gets("#{name}: ") |> String.trim() |> marshall_numeric

      new_template ->
        (fn ->
           IO.puts("#{name}\n#{String.duplicate("-", String.length(name))}")

           names = Map.keys(new_template)

           %{}
           |> (&Enum.reduce(names, &1, fn new_name, new_input ->
                 get_input(new_input, new_name, new_template)
               end)).()
         end).()
    end
    |> (&Map.put_new(input, name, &1)).()
  end

  defp finish() do
    IO.puts("Goodbye")
  end

  defp get_command() do
    IO.gets(@prompt) |> String.trim()
  end

  defp help(prefix \\ "") do
    IO.puts(prefix)

    IO.puts("help:\tthis help\n")

    ActionMap.list_actions()
    |> Enum.map(fn {action, description} ->
      IO.puts("#{action}: #{description}")
    end)

    IO.puts("exit:\tclose the console\n")

    run()
  end
end
