defmodule ImpactMap do
  @behaviour PlotCommands

  @moduledoc """
  Generates scatter plots of impact speed and phase on the impact-surface
  """

  @impl PlotCommands
  def command_for_plot(label) do
    ["-", :title, label, :with, :dots]
  end

  @impl PlotCommands
  def commands_for_axes() do
    [
      PlotCommands.axis_label_command(true, "{/Symbol f}"),
      PlotCommands.axis_label_command(false, "v"),
      PlotCommands.range_command(true, 0, 1),
      [
        :set,
        :xtics,
        "(\"0\" 0, \"{/Symbol p}/{/Symbol w}\" 0.5, \"2{/Symbol p}/{/Symbol w}\" 1)"
        |> to_charlist
      ],
      PlotCommands.range_command(false, 0, nil)
    ]
  end

  @impl PlotCommands
  def from_args(args) do
    args
    |> (&[
          CoreWrapper.from_args(ImpactPoint, &1, "initial_point"),
          CoreWrapper.from_args(SystemParameters, &1, "params"),
          CoreWrapper.from_args(Integer, &1, "num_iterations")
        ]).()
    |> Enum.reduce([], fn x, acc ->
      case x do
        {:error, message} ->
          case acc do
            {:error, acc_message} -> {:error, "#{acc_message}\n#{message}"}
            _ -> {:error, message}
          end

        _ ->
          case acc do
            {:error, _} -> acc
            _ -> acc ++ [x]
          end
      end
    end)
  end

  @impl PlotCommands
  def data_for_plot(args, title_args) do
    case from_args(args) do
      {:error, message} ->
        {:error, message}

      [initial_point, params, num_iterations] ->
        elem(MotionBetweenImpacts.iterate_impacts(initial_point, params, num_iterations), 0)
        |> Stream.map(&ImpactPoint.point_to_list(&1))
        |> (&{PlotCommands.label_from_args(title_args, args), &1}).()
    end
  end
end
