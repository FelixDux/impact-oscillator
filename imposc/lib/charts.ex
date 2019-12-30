import Gnuplot
import ImposcUtils
import ImpactPoint
import SystemParameters
import MotionBetweenImpacts
import OneNLoci

defmodule ImpactMap do
  @moduledoc """
  Generates scatter plots of impact speed and phase on the impact-surface
  """

   def chart_impacts(%ImpactPoint{}=initial_point, %SystemParameters{} = params, num_iterations \\ 1000) do
    dataset = MotionBetweenImpacts.iterate_impacts(initial_point, params, num_iterations) |> Enum.map(& ImpactPoint.point_to_list(&1))
    {:ok, cmd} = Gnuplot.plot([
      [:set, :title, "Impact map for omega = #{params.omega}, sigma = #{params.sigma}, r = #{params.r}"],
      [:plot, "-", :with, :points, :pointtype, 7, :ps, 0.1]
    ], [dataset])
    IO.puts(cmd)
  end
end

defmodule Curves do

  def sigma_ellipse(n, omega, r, num_points \\ 100) do
    dataset = OneNLoci.curves_for_fixed_omega(n, omega, r, num_points)
    {:ok, cmd} = Gnuplot.plot([
      [:set, :title, "Sigma response curve for (1, #{n}) orbits for omega = #{omega}, r = #{r}"],
      Gnuplot.plots([
        ["-", :title, "Stable", :with, :lines],
        ["-", :title, "Unstable", :with, :lines]
        ])], dataset)
    IO.puts(cmd)
  end
end

defmodule Mix.Tasks.Scatter do
  use Mix.Task

  @spec run(any) :: {:ok, binary}
  def run(_) do
    initial_point = %ImpactPoint{phi: 0.5, v: 0.5}
    params = %SystemParameters{omega: 2.8, r: 0.8, sigma: 0}
    num_iterations = 10000

    ImpactMap.chart_impacts(initial_point, params, num_iterations)
  end
end


defmodule Mix.Tasks.Ellipse do
  use Mix.Task

  @spec run(any) :: {:ok, binary}
  def run(_) do
    Curves.sigma_ellipse(1, 2.8, 0.8)
  end
end
