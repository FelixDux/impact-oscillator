defmodule EllipseAction do
  @behaviour Action

  @moduledoc """
  Generates a (1, n) orbit sigma response plot 
  """

  @impl Action
  def expects_list?() do
    false
  end

  @doc """
  Generates a (1, n) orbit sigma response plot using arguments initialised from `:args`.

  `:options` specifies available options, including whether output is to be directed to a file instead of to the terminal.
  """
  @impl Action
  def execute(args, options) do
    PlotCommands.draw(
      SigmaCurves,
      [args],
      "{/Symbol s}-response curve for (1, n) orbits",
      options
    )
  end

  @doc """
  Specifies the arguments required for a (1, n) sigma response plot 
  """
  @impl Action
  def requirements() do
    %{
      "n" => nil,
      "omega" => nil,
      "r" => nil,
      "num_points" => nil
    }
  end

  @doc """
  Specifies the options available for the action
  """
  @impl Action
  def expected_options() do
    %{"outfile" => nil}
  end

  @doc """
  Returns a description of the action
  """
  @impl Action
  def description() do
    @moduledoc
  end
end
