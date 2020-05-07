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
    args = [%{"n" => 2, "omega" => 3.8, "r" => 0.8, "num_points" => 100}]

    PlotCommands.draw(SigmaCurves, args, "{/Symbol s}-ellipse")
  end
end

defmodule Mix.Tasks.Timeseries do
  use Mix.Task

  @spec run(any) :: {atom(), iodata()} | atom()
  def run(_) do
    args = [
      %{
        "start_impact" => %{"phi" => 0.5, "v" => 0.15},
        "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8}
      },
      %{
        "start_impact" => %{"phi" => 0.5, "v" => 0.15},
        "params" => %{"omega" => 2.8, "sigma" => 0.2, "r" => 0.8}
      }
    ]

    PlotCommands.draw(TimeSeries, args, "Impact Map")
  end
end
