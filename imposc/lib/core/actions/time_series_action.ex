defmodule TimeSeriesAction do
  @behaviour Action

  @moduledoc """
  Generates a time-series plot
  """

  @impl Action
  def expects_list?() do
    false
  end

  @doc """
  Generates a time-series plot using arguments initialised from `:args`.

  `:options` specifies available options, including whether output is to be directed to a file instead of to the terminal.
  """
  @impl Action
  def execute(args, options) do
    PlotCommands.draw(TimeSeries, [args], "Time Series", options)
  end

  @doc """
  Specifies the arguments required for a time series plot 
  """
  @impl Action
  def requirements() do
    %{
      "start_impact" => %{"phi" => nil, "v" => nil},
      "params" => %{"omega" => nil, "sigma" => nil, "r" => nil}
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
