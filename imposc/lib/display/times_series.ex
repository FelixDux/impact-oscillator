defmodule TimeSeries do
  @spec time_series(%ImpactPoint{}, %SystemParameters{}) :: {atom(), iodata()} | atom()
  def time_series(%ImpactPoint{} = start_impact, %SystemParameters{} = params) do
    {initial_points, _} = MotionBetweenImpacts.iterate_impacts(start_impact, params, 1)

    new_impact = Enum.at(initial_points, -1)

    {_points, states} = MotionBetweenImpacts.iterate_impacts(new_impact, params, 50, true)

    dataset = Stream.map(states, &[&1.t, &1.x])

    case Gnuplot.plot(
           [
             PlotCommands.chart_title(
               "Time series for {/Symbol w} = #{params.omega}, {/Symbol s} = #{params.sigma}, r = #{
                 params.r
               }"
             ),
             [:plot, "-", :with, :lines]
           ],
           [dataset]
         ) do
      {:ok, _cmd} -> :ok
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end
end

