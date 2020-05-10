defmodule EllipseAction do
  @behaviour Action

  @moduledoc """
  Generates a (1, n) orbit sigma response plot 
  """

  @doc """
  Generates a (1, n) orbit sigma response plot using arguments initialised from `:args`.
  """
  @impl Action
  def execute(args, outfile) do
    PlotCommands.draw(
      SigmaCurves,
      [args],
      "{/Symbol s}-response curve for (1, n) orbits",
      outfile
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
  Returns a description of the action
  """
  @impl Action
  def description() do
    @moduledoc
  end
end
