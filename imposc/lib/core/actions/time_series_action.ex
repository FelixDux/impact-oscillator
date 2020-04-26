defmodule TimeSeriesAction do
  @behaviour Action

  @doc """
  Generates a time-series plot using arguments initialised from `:args`.
  """
  @impl Action
  def execute(args) do
    args
    |> (&TimeSeries.time_series(
          CoreWrapper.from_args(ImpactPoint, &1, "start_impact"),
          CoreWrapper.from_args(SystemParameters, &1, "params")
        )).()
  end

end
