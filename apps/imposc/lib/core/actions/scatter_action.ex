defmodule ScatterAction do
  @behaviour Action

  @moduledoc """
  Generates a scatter plot
  """

  @impl Action
  def expects_list?() do
    false
  end

  @doc """
  Generates a scatter plot using arguments initialised from `:args`.

  `:options` specifies available options, including whether output is to be directed to a file instead of to the terminal.
  """
  @impl Action
  def execute(args, options) do
    PlotCommands.draw(ImpactMap, [args], "Impact Map", options)
  end

  @doc """
  Specifies the arguments required for a scatter plot 
  """
  @impl Action
  def requirements() do
    %{
      "initial_point" => %{"phi" => nil, "v" => nil},
      "params" => %{"omega" => nil, "sigma" => nil, "r" => nil},
      "num_iterations" => nil
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
