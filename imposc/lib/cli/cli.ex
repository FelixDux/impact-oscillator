defmodule CLI do
  @moduledoc """
  Interface for launching a command line application.

  The CLI application receives JSON input and, depending on command line options, generates:

  - graphics in a window
  - graphics in a PNG file
  - JSON to standard output
  """

  defmacro const_options do
    quote do: %{
            switches: [help: :boolean, json: :boolean, window: :boolean, png: :boolean],
            aliases: [h: :help, j: :json, w: :window, p: :png],
            help: [
              help: "Returns this help message",
              json: "Writes all output data to standard output as a JSON string",
              window: "Directs any graphical output to a gnuplot window",
              png:
                "Writes any graphical output to a PNG file and returns the file path to the standard output. If used with --json, the file path is included in the JSON string."
            ]
          }
  end

  @spec parse_args([String]) :: {[], [], []}
  def parse_args(args) do
    %{switches: switches, aliases: aliases} = const_options()

    OptionParser.parse(args, strict: switches, aliases: aliases)
  end

  def process(:help) do
    %{help: help, aliases: aliases} = const_options
    for {k, v} <- aliases, do: IO.puts("\n-#{k}, --#{v}:\t#{help[v]}")
    #    System.halt(0)
  end

  def process({options, args}) do
    IO.puts("Hello")
  end
end
