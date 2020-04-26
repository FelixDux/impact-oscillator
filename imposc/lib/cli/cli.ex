defmodule CLI do
  @moduledoc """
  Interface for launching a command line application.

  The CLI application receives JSON input and, depending on command line options, launches the application in one of 
  three modes:

   - a one_shot mode which accepts JSON from the standard input, interprets it into commands, generates any graphics and
     returns any text output (e.g. JSON) to the standard output and exits.
   - a mode which launches a console interface
   - a mode which launches a REST server
  """

  @const_options %{
    switches: [help: :boolean, one_shot: :boolean, console: :boolean, rest: :boolean],
    aliases: [h: :help, o: :one_shot, c: :console, r: :rest],
    help: [
      help: "Returns this help message",
      one_shot:
        "Accepts JSON from the standard input, interprets it into commands, generates any graphics and returns any text output (e.g. JSON) to the standard output and exits",
      console: "Launches as a console application",
      rest: "Launches as a REST server"
    ]
  }

  def const_options(), do: @const_options
  @spec parse_args([String]) :: {[], [], []}
  def parse_args(args) do
    %{switches: switches, aliases: aliases} = const_options()

    OptionParser.parse(args, strict: switches, aliases: aliases)
  end

  defp usage() do
    "#{
      :application.get_application(__MODULE__)
      |> (fn result ->
            case result do
              {:ok, name} -> name
              _ -> "imposc"
            end
          end).()
    } [options]"
  end

  def process({[help: true], _, _}) do
    IO.puts("Usage: #{usage()}\n")
    %{help: help, aliases: aliases} = const_options()
    for {k, v} <- aliases, do: IO.puts("\n-#{k}, --#{v}:\t#{help[v]}")
    #    System.halt(0)
  end

  def process({[one_shot: true], _, _}) do
    CoreWrapper.process_input()
  end

  def process(args) do
    IO.puts("Not yet implemented:")

    IO.inspect(args)
  end

  def main(args) do
    args |> parse_args |> process
  end
end
