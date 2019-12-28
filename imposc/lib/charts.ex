import Gnuplot
import Imposc
import ImpactPoint
import SystemParameters
import MotionBetweenImpacts

defmodule ImpactMap do
  @moduledoc """
  Generates scatter plots of impact speed and phase on the impact-surface
  """

   def chart_impacts(%ImpactPoint{}=initial_point, %SystemParameters{} = params, num_iterations \\ 1000) do
    dataset = MotionBetweenImpacts.iterate_impacts(initial_point, params, num_iterations) |> Enum.map(& ImpactPoint.point_to_list(&1))
    {:ok, _cmd} = Gnuplot.plot([
      [:set, :title, "Impact map"],
      [:plot, "-", :with, :points]
    ], [dataset])
    # IO.puts(dataset)
  end
end

defmodule Mix.Tasks.Scatter do
  use Mix.Task

  @spec run(any) :: {:ok, binary}
  def run(_) do
    # dataset = for _ <- 0..1000, do: [:rand.uniform(), :rand.normal()]
    # {:ok, _cmd} = Gnuplot.plot([
    #   [:set, :title, "Impact map"],
    #   [:plot, "-", :with, :points]
    # ], [dataset])
    initial_point = %ImpactPoint{phi: 0.5, v: 0.5}
    params = %SystemParameters{omega: 2.8, r: 0.8, sigma: 0}
    num_iterations = 10000

    ImpactMap.chart_impacts(initial_point, params, num_iterations)
  end
end
