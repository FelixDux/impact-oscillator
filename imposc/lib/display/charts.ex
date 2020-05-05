import SystemParameters


defmodule PlotCommands do

  def chart_title(title) do
    [:set, :title, title]
  end

  @callback command_for_plot(iodata()) :: [any()]

  @callback from_args(map()) :: [any()]

  @callback data_for_plot(map()) :: {iodata(), [any()]}

  def collate_data(implementation, arg_list) do
    data = arg_list |> Enum.map(
    fn args ->
    Task.async(fn ->
      args |> implementation.data_for_plot
    end)
    |> (&Task.await(&1)).()
    end) 
    #|> Enum.map(&Task.await(&1))
    #|> IO.inspect

    0..1 |> Enum.map(fn i -> data |> Enum.map(&elem(&1, i)) end)|> List.to_tuple
  end

  @spec draw(module(), [map()], iodata()) :: {atom(), iodata()} | atom()
  def draw(implementation, arg_list, title) do
    {labels, datasets} = collate_data(implementation, arg_list)

    commands = labels |> Enum.map(&implementation.command_for_plot(&1)) |>
   (& [chart_title(title), Gnuplot.plots(&1)]).()
   |> IO.inspect

    case Gnuplot.plot( commands, datasets) do
      {:ok, _cmd} -> :ok
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end
end

defmodule ImpactMap do
  @behaviour PlotCommands

  @moduledoc """
  Generates scatter plots of impact speed and phase on the impact-surface
  """

  @impl PlotCommands
  def command_for_plot(label) do
     [:plot, "-", :title, label, :with, :points, :pointtype, 7, :ps, 0.1] 
  end

  @impl PlotCommands
  def from_args(args) do
    args
    |> (&[
          CoreWrapper.from_args(ImpactPoint, &1, "initial_point"),
          CoreWrapper.from_args(SystemParameters, &1, "params"),
          CoreWrapper.from_args(Integer, &1, "num_iterations")
    ]).()
  end

  @impl PlotCommands
  def data_for_plot(args) do
    [initial_point, params, num_iterations] = from_args(args)

    dataset =
      elem(MotionBetweenImpacts.iterate_impacts(initial_point, params, num_iterations), 0)
      |> Stream.map(&ImpactPoint.point_to_list(&1))

   {"{/Symbol w} = #{params.omega}, {/Symbol s} = #{params.sigma}, r = #{params.r}, ({/Symbol f}_0, v_0) = #{initial_point}", dataset}
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
                    PlotCommands.chart_title(
                      "{/Symbol s}-response curve for (1, #{n}) orbits for {/Symbol w} = #{omega}, r = #{r}"
                    ),
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
                    PlotCommands.chart_title(
               "Time series for {/Symbol w} = #{params.omega}, {/Symbol s} = #{params.sigma}, r = #{params.r}"
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

defmodule Mix.Tasks.Scatter do
  use Mix.Task

  @spec run(any) :: {atom(), iodata()} | atom()
  def run(_) do
    args = [
      %{"initial_point"=> %{"phi"=> 0.5, "v"=> 0.15}, "params"=> %{"omega"=> 2.8, "sigma"=> 0, "r"=> 0.8}, "num_iterations"=> 10000} ,
%{"initial_point"=> %{"phi"=> 0.5, "v"=> 0.15}, "params"=> %{"omega"=> 2.8, "sigma"=> 0.2, "r"=> 0.8}, "num_iterations"=> 10000}
      ]

    PlotCommands.draw(ImpactMap, args, "Impact Map")
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
