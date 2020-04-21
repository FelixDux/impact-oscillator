defmodule CLI do
  @moduledoc """
  Interface for launching a command line application.

  The CLI application receives JSON input and, depending on command line options, generates:

  - graphics in a window
  - graphics in a file
  - JSON to standard output
  """

  @appdoc """
  TODO:
  """

  @spec parse_args([String]) :: {[], [], []}
  def parse_args(args) do
    switches = [help: :boolean, json: :boolean, window: :boolean, file: :boolean]
    aliases = [h: :help, j: :json, w: :window, f: :file]

    OptionParser.parse(args, strict: switches, aliases: aliases)
  end

  def process(:help) do
    IO.puts @appdoc
    System.halt(0)
  end

  def process({options,args}) do
    IO.puts("Hello")
  end
end
