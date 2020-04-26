defmodule ScatterAction do
  @behaviour Action

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
end
