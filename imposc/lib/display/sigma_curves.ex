defmodule SigmaCurves do
  @moduledoc """
  Generates sigma-response curves for (1, n) orbits
  """
  @behaviour PlotCommands

  @impl PlotCommands
  def command_for_plot(label) do
    ["-", :title, label, :with, :lines]
  end

  @impl PlotCommands
  def commands_for_axes() do
    [
      PlotCommands.axis_label_command(true, "{/Symbol s}"),
      PlotCommands.axis_label_command(false, "V_n"),
      PlotCommands.range_command(false, 0, nil)
    ]
  end

  @impl PlotCommands
  def from_args(args) do
    args
    |> (&[
          CoreWrapper.from_args(Integer, &1, "n"),
          CoreWrapper.from_args(Float, &1, "omega"),
          CoreWrapper.from_args(Float, &1, "r"),
          CoreWrapper.from_args(Integer, &1, "num_points")
        ]).()
  end

  @impl PlotCommands
  def data_for_plot(args) do
    [n, omega, r, num_points] = from_args(args)

    case OneNLoci.curves_for_fixed_omega(n, omega, r, num_points) do
      {:ok, dataset} ->
        {
          [
            "{/Symbol w} = #{omega}, r = #{r}, n = #{n}, stable",
            "{/Symbol w} = #{omega}, r = #{r}, n = #{n}, unstable"
          ],
          dataset
        }

      # |> IO.inspect

      {:error, reason} ->
        {:error, "Error #{reason} encountered generating chart"}
    end
  end
end
