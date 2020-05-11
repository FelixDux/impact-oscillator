defmodule TimeSeries do
  @behaviour PlotCommands

  @impl PlotCommands
  def command_for_plot(label) do
    ["-", :title, label, :with, :lines]
  end

  @impl PlotCommands
  def commands_for_axes() do
    [
      PlotCommands.axis_label_command(true, "t"),
      PlotCommands.axis_label_command(false, "x")
    ]
  end

  @impl PlotCommands
  def from_args(args) do
    args
    |> (&[
          CoreWrapper.from_args(ImpactPoint, &1, "start_impact"),
          CoreWrapper.from_args(SystemParameters, &1, "params")
        ]).()
  end

  @impl PlotCommands
  def data_for_plot(args) do
    [start_impact, params] = from_args(args)

    {initial_points, _} = MotionBetweenImpacts.iterate_impacts(start_impact, params, 1)

    new_impact = Enum.at(initial_points, -1)

    {_points, states} = MotionBetweenImpacts.iterate_impacts(new_impact, params, 50, true)

    dataset = Stream.map(states, &[&1.t, &1.x])

    {"{/Symbol w} = #{params.omega}, {/Symbol s} = #{params.sigma}, r = #{params.r}, ({/Symbol f}_0, v_0) = #{
       start_impact
     }", dataset}
  end
end
