defmodule PlotCommands do
  def chart_title(title) do
    [:set, :title, title]
  end

  @callback command_for_plot(iodata()) :: [any()]

  @callback from_args(map()) :: [any()]

  @callback data_for_plot(map()) :: {iodata(), [any()]} | {[iodata()], [[any()]]}

  @spec axis_label_command(boolean(), iodata()) :: [any()]
  def axis_label_command(x_axis, text) do
    [:set, if(x_axis, do: :xlabel, else: :ylabel), text] ++
      if x_axis, do: [:offset, '0,0.25'], else: [:rotate, :by, 0]
  end

  def outfile_arg(args) do
    case CoreWrapper.from_args(String, args, "outfile") do
      {:error, _} -> nil
      outfile -> outfile
    end
  end

  def outfile_commands(outfile) do
    command_lookup = %{"png" => :pngcairo, "svg" => :svg}

    if outfile do
      case String.downcase(outfile)
           |> (&{&1, Map.fetch(command_lookup, &1)}).() do
        {_, :error} ->
          {"", []}

        {extension, {:ok, terminal}} ->
          ImageCache.offer_new_file(%ImageCache{}, extension)
          |> (&(case &1 do
                  {:ok, filename} -> {filename, [[:set, :term, terminal], [:set, :output, filename]]}
                  _ -> {"", []}
                end)).()
      end
    else
      {"", []}
    end
  end

  @spec range_command(boolean(), number(), number()) :: [any()]
  def range_command(x_axis, min_value, max_value) when is_nil(min_value) do
    [
      :set,
      if(x_axis, do: :xrange, else: :yrange),
      ("[:" <>
         Gnuplot.Commands.Command.formatg(max_value) <> "]")
      |> to_charlist
    ]
  end

  def range_command(x_axis, min_value, max_value) when is_nil(max_value) do
    [
      :set,
      if(x_axis, do: :xrange, else: :yrange),
      ("[" <>
         Gnuplot.Commands.Command.formatg(min_value) <> ":]")
      |> to_charlist
    ]
  end

  def range_command(x_axis, min_value, max_value) do
    [:set, if(x_axis, do: :xrange, else: :yrange), min_value..max_value]
  end

  def legend_commands() do
    [
      [:set, :key, :box],
      [:set, :key, :below]
    ]
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
    0..1
    |> Enum.map(fn i -> data |> Enum.map(&elem(&1, i)) end)
    |> List.to_tuple()
  end

  def collate_for_plot(implementation, args) do
    Task.async(fn ->
      args
      |> (&implementation.data_for_plot(&1)).()
      |> (&{elem(&1, 0), elem(&1, 1)}).()
    end)
  end

  def collate_data(implementation, arg_list) do
    # For each set of arguments get the plot data, which be a tuple
    # comprising the label and the data points.
    data =
      arg_list
      |> Enum.map(fn args -> collate_for_plot(implementation, args) end)
      |> Enum.map(&Task.await(&1))

    # We now have a list of tuples, which we convert into a tuple of lists
    # as the labels and the data have to be passed to difference arguments
    # in `:Gnuplot.plot`

    data |> flatten_plot_data_list |> slice_plot_data
  end

  @spec draw(module(), [map()], iodata(), iodata()) :: {atom(), iodata()} | atom()
  def draw(implementation, arg_list, title, file_format \\ "") do
    {labels, datasets} = collate_data(implementation, arg_list)
    
    {image_file, image_file_commands} = outfile_commands(file_format) 

    commands =
      labels
      |> Enum.map(&implementation.command_for_plot(&1))
      |> (fn command ->
            [chart_title(title)] ++
              implementation.commands_for_axes() ++
              legend_commands() ++
              image_file_commands ++
              [Gnuplot.plots(command)]
          end).()

    case Gnuplot.plot(commands, datasets) do
      {:ok, _cmd} -> {:ok, image_file}
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end
end
