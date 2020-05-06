
defmodule Mix.Tasks.Scatter do
  use Mix.Task

  @spec run(any) :: {atom(), iodata()} | atom()
  def run(_) do
    args = [
      %{
        "initial_point" => %{"phi" => 0.5, "v" => 0.15},
        "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8},
        "num_iterations" => 10000
      },
      %{
        "initial_point" => %{"phi" => 0.5, "v" => 0.15},
        "params" => %{"omega" => 2.8, "sigma" => 0.2, "r" => 0.8},
        "num_iterations" => 10000
      }
    ]

    PlotCommands.draw(ImpactMap, args, "Impact Map")
  end
end

defmodule Mix.Tasks.Ellipse do
  use Mix.Task

  @spec run(any) :: {atom(), iodata()} | atom()
  def run(_) do
    SigmaCurves.sigma_ellipse(2, 4, 0.4)
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
