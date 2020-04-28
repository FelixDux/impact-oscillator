import SystemParameters

defmodule ImpactMap do
  @moduledoc """
  Generates scatter plots of impact speed and phase on the impact-surface
  """

  @spec chart_impacts(%ImpactPoint{}, %SystemParameters{}, integer()) ::
          {atom(), iodata()} | atom()
  def chart_impacts(
        %ImpactPoint{} = initial_point,
        %SystemParameters{} = params,
        num_iterations \\ 1000
      ) do
    dataset =
      elem(MotionBetweenImpacts.iterate_impacts(initial_point, params, num_iterations), 0)
      |> Stream.map(&ImpactPoint.point_to_list(&1))

    case Gnuplot.plot(
           [
             [
               :set,
               :title,
               "Impact map for omega = #{params.omega}, sigma = #{params.sigma}, r = #{params.r}"
             ],
             [:plot, "-", :with, :points, :pointtype, 7, :ps, 0.1]
           ],
           [dataset]
         ) do
      {:ok, _cmd} -> :ok
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end
end

defmodule Curves do
  @moduledoc """
  Generates sigma-response curves for (1, n) orbits
  """

  @spec sigma_ellipse(integer(), number(), number(), integer()) :: {atom(), iodata()} | atom()
  def sigma_ellipse(n, omega, r, num_points \\ 1000) do
    case OneNLoci.curves_for_fixed_omega(n, omega, r, num_points) do
      {:ok, dataset} ->
        (fn ->
           case Gnuplot.plot(
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
                ) do
             {:ok, _cmd} -> :ok
             {:error, message} -> {:error, message}
             _ -> {:error, "Unknown error generating chart"}
           end
         end).()

      {:error, reason} ->
        {:error, "Error #{reason} encountered generating chart"}
    end
  end
end

defmodule TimeSeries do
  @spec time_series(%ImpactPoint{}, %SystemParameters{}) :: {atom(), iodata()} | atom()
  def time_series(%ImpactPoint{} = start_impact, %SystemParameters{} = params) do
    {initial_points, _} = MotionBetweenImpacts.iterate_impacts(start_impact, params, 1)

    new_impact = Enum.at(initial_points, -1)

    {_points, states} = MotionBetweenImpacts.iterate_impacts(new_impact, params, 50, true)

    dataset = Stream.map(states, &[&1.t, &1.x])

    case Gnuplot.plot(
           [
             [
               :set,
               :title,
               "Time series for omega = #{params.omega}, sigma = #{params.sigma}, r = #{params.r}"
             ],
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

defmodule Mix.Tasks.Scatter do
  use Mix.Task

  @spec run(any) :: {atom(), iodata()} | atom()
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

  @spec run(any) :: {atom(), iodata()} | atom()
  def run(_) do
    Curves.sigma_ellipse(2, 4, 0.4)
  end
end

defmodule Mix.Tasks.Timeseries do
  use Mix.Task

  @spec run(any) :: {atom(), iodata()} | atom()
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
