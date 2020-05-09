defmodule PlotCommands do
  def chart_title(title) do
    [:set, :title, title]
  end

  @callback command_for_plot(iodata()) :: [any()]

  @callback from_args(map()) :: [any()]

  @callback data_for_plot(map()) :: {iodata(), [any()]} | {[iodata()], [[any()]]}

  @spec axis_label_command(boolean(), iodata()) :: [any()]
  def axis_label_command(x_axis, text) do
    [:set, (if x_axis, do: :xlabel, else: :ylabel), text]
  end

  @spec range_command(boolean(), number(), number()) :: [any()]
  def range_command(x_axis, min_value, max_value) when is_nil(min_value) do
    [:set, (if x_axis, do: :xrange, else: :yrange), "[:" <>
      Gnuplot.Commands.Command.formatg(max_value) <> "]"]
  end

  def range_command(x_axis, min_value, max_value) when is_nil(max_value) do
    [:set, (if x_axis, do: :xrange, else: :yrange), "[" <>
      Gnuplot.Commands.Command.formatg(min_value) <> ":5]"]
  end

  def range_command(x_axis, min_value, max_value) do
    [:set, (if x_axis, do: :xrange, else: :yrange), min_value..max_value]
  end

  @callback commands_for_axes() :: [[any()]]

  defp flatten_plot_data(data) do
    # In some cases `:data_for_plot` may generate multiple datasets
    {label, data_points} = data

    if is_list(label) do
      n_labels = Enum.count(label)

      if is_list(data_points) and
           data_points |> List.first() |> is_list and
           n_labels == Enum.count(data_points) do
        0..(n_labels - 1)
        |> Enum.reduce([], fn i, acc ->
          acc ++ [{Enum.at(label, i), Enum.at(data_points, i)}]
        end)
      else
        raise "Type or size mismatch in plot data"
      end
    else
      [data]
    end
  end

  defp flatten_plot_data_list(data) do
    data
    |> Enum.reduce([], fn data_tuple, acc ->
      acc ++ flatten_plot_data(data_tuple)
    end)
  end

  defp slice_plot_data(data) do
    0..1 |> Enum.map(fn i -> data |> Enum.map(&elem(&1, i)) end) |> List.to_tuple()
  end

  def collate_data(implementation, arg_list) do
    # For each set of arguments get the plot data, which be a tuple
    # comprising the label and the data points.
    data =
      arg_list
      |> Enum.map(fn args ->
        Task.async(fn ->
          args |> implementation.data_for_plot
        end)
        |> (&Task.await(&1)).()
      end)

    # We now have a list of tuples, which we convert into a tuple of lists
    # as the labels and the data have to be passed to difference arguments
    # in `:Gnuplot.plot`

    data |> flatten_plot_data_list |> slice_plot_data
  end

  @spec draw(module(), [map()], iodata()) :: {atom(), iodata()} | atom()
  def draw(implementation, arg_list, title) do
    {labels, datasets} = collate_data(implementation, arg_list)

    commands =
      labels
      |> Enum.map(&implementation.command_for_plot(&1))
      |> (&[chart_title(title)] ++ implementation.commands_for_axes() ++
        [Gnuplot.plots(&1)]).()

    case Gnuplot.plot(commands, datasets) do
      {:ok, _cmd} -> :ok
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end
end
