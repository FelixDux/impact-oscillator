import SystemParameters

defmodule ImpactMap do
  @moduledoc """
  Generates scatter plots of impact speed and phase on the impact-surface
  """

  def chart_impacts(
        %ImpactPoint{} = initial_point,
        %SystemParameters{} = params,
        num_iterations \\ 1000
      ) do
    IO.inspect(params)
    IO.inspect(initial_point)

    dataset =
      elem(MotionBetweenImpacts.iterate_impacts(initial_point, params, num_iterations), 0)
      |> Stream.map(&ImpactPoint.point_to_list(&1))

    {:ok, _cmd} =
      Gnuplot.plot(
        [
          [
            :set,
            :title,
            "Impact map for omega = #{params.omega}, sigma = #{params.sigma}, r = #{params.r}"
          ],
          [:plot, "-", :with, :points, :pointtype, 7, :ps, 0.1]
        ],
        [dataset]
      )

    #    IO.puts(cmd)
  end
end

defmodule Curves do
  def sigma_ellipse(n, omega, r, num_points \\ 1000) do
    case OneNLoci.curves_for_fixed_omega(n, omega, r, num_points) do
      {:ok, dataset} ->
        (fn ->
           {:ok, _cmd} =
             Gnuplot.plot(
               [
                 [
                   :set,
                   :title,
                   "Sigma response curve for (1, #{n}) orbits for omega = #{omega}, r = #{r}"
                 ],
                 Gnuplot.plots([
                   ["-", :title, "Stable", :with, :lines],
                   ["-", :title, "Unstable", :with, :lines]
                 ])
               ],
               dataset
             )

           #    IO.puts(cmd)
           #    IO.inspect dataset
         end).()

      # TODO: implement error logger
      {:error, reason} ->
        IO.puts(reason)

      other ->
        IO.inspect(other)
    end
  end
end

defmodule TimeSeries do
  def time_series(%ImpactPoint{} = start_impact, %SystemParameters{} = params) do
    {initial_points, _} = MotionBetweenImpacts.iterate_impacts(start_impact, params, 1)

    new_impact = Enum.at(initial_points, -1)

    {_points, states} = MotionBetweenImpacts.iterate_impacts(new_impact, params, 50, true)

    dataset = Stream.map(states, &[&1.t, &1.x])

    {:ok, _cmd} =
      Gnuplot.plot(
        [
          [
            :set,
            :title,
            "Time series for omega = #{params.omega}, sigma = #{params.sigma}, r = #{params.r}"
          ],
          [:plot, "-", :with, :lines]
        ],
        [dataset]
      )

    #    IO.puts(cmd)
    #    IO.inspect dataset

    #    Enum.map(points, &IO.puts("#{&1.t}, #{&1.phi}, #{&1.v}"))
  end
end

defmodule Mix.Tasks.Scatter do
  use Mix.Task

  #  @spec run(any) :: {:ok, binary}
  def run(_) do
    initial_point = %ImpactPoint{phi: 0.0, v: 0.01}
    params = %SystemParameters{omega: 2.7, r: 0.8, sigma: 0}
    # points = OneNLoci.orbits_for_params(params, 1)
    # initial_point = Enum.at(points, 0)
    num_iterations = 10000

    ImpactMap.chart_impacts(initial_point, params, num_iterations)
  end
end

defmodule Mix.Tasks.Ellipse do
  use Mix.Task

  #  @spec run(any) :: {:ok, binary}
  def run(_) do
    Curves.sigma_ellipse(2, 4, 0.4)
  end
end

defmodule Mix.Tasks.Timeseries do
  use Mix.Task

  #  @spec run(any) :: {:ok, binary}
  def run(_) do
    params = %SystemParameters{omega: 2.7, r: 0.8, sigma: 0}
    #    points = OneNLoci.orbits_for_params(params, 1)
    # IO.inspect points
    #    initial_point = Enum.at(points, 0)
    initial_point = %ImpactPoint{phi: 0, v: 0.01}
    TimeSeries.time_series(initial_point, params)
    # IO.inspect points
  end
end
