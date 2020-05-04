defmodule ScatterAction do
  @behaviour Action

  @moduledoc """
  Generates a scatter plot
  """

  @doc """
  Generates a scatter plot using arguments initialised from `:args`.
  """
  @impl Action
  def execute(args) do
    args
    |> (&ImpactMap.chart_impacts(
          CoreWrapper.from_args(ImpactPoint, &1, "initial_point"),
          CoreWrapper.from_args(SystemParameters, &1, "params"),
          CoreWrapper.from_args(Integer, &1, "num_iterations")
        )).()
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
  Returns a description of the action
  """
  @impl Action
  def description() do
    @moduledoc
  end
end