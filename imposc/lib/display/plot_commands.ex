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
    with {:error, _} <- CoreWrapper.from_args(String, args, "outfile"), do: nil
  end

  def outfile_commands(options) do
    command_lookup = %{"png" => :pngcairo, "svg" => :svg}

    file_format =
      (fn ->
         case Map.fetch(options, "outfile") do
           {:ok, result} -> result
           _ -> nil
         end
       end).()

    if file_format do
      case String.downcase(file_format)
           |> (&{&1, Map.fetch(command_lookup, &1)}).() do
        {_, :error} ->
          {"", []}

        {extension, {:ok, terminal}} ->
          ImageCache.offer_new_file(%ImageCache{}, extension)
          |> (&(case &1 do
                  {:ok, filename} ->
                    {filename, [[:set, :term, terminal], [:set, :output, filename]]}

                  _ ->
                    {"", []}
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

  defp unset_commands_for_axes() do
    (fn ->
    [:xlabel, :ylabel, :xrange, :yrange, :xtics, :ytics]
    |> Enum.map(&[:unset, &1])
    end).()
    ++
    (fn ->
    [:xtics, :ytics]
    |> Enum.map(&[:set, &1])
    end).()
  end

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
      # TODO: make fault-tolerant
      |> Enum.map(&Task.await(&1, :infinity))

    # We now have a list of tuples, which we convert into a tuple of lists
    # as the labels and the data have to be passed to difference arguments
    # in `:Gnuplot.plot`

    data |> flatten_plot_data_list |> slice_plot_data
  end

  def collate_for_chart(implementation, arg_list) do
    {labels, datasets} = collate_data(implementation, arg_list)

    commands =
      labels
      |> Enum.map(&implementation.command_for_plot(&1))
      |> (fn command ->
            implementation.commands_for_axes() ++
              legend_commands() ++
                [Gnuplot.plots(command)] ++
              unset_commands_for_axes()
#++ [chart_title(title)] 
          end).()

    {commands, datasets}
  end

  def collate_for_image(chart_specs) do
    chart_specs
    |> Enum.reduce(
      {[], []},
      fn {implementation, arg_list}, {commands, datasets} ->
        {new_commands, new_datasets} = collate_for_chart(implementation, arg_list)

        {commands ++ new_commands, datasets ++ new_datasets}
      end
    )
  end

  defp multi_plot_layout(n_charts, n_rows \\ 1, n_columns \\ 1)

  defp multi_plot_layout(n_charts, n_rows, n_columns) when n_rows * n_columns >= n_charts do
    {n_rows, n_columns}
  end

  defp multi_plot_layout(n_charts, n_rows, n_columns) when n_rows < n_columns do
    multi_plot_layout(n_charts, n_rows + 1, n_columns)
  end

  defp multi_plot_layout(n_charts, n_rows, n_columns) do
    multi_plot_layout(n_charts, n_rows, n_columns + 1)
  end

  def commands_for_image(title, options, n_charts \\ 1) do
    {image_file, image_file_commands} = outfile_commands(options)

    multiplot_command =
      if n_charts > 1 do
        [
          [
            :set,
            :multiplot,
            :layout,
            n_charts
            |> multi_plot_layout
            |> (fn {n_rows, n_columns} ->
                  '#{n_rows}, #{n_columns}'
            end).(),
            :title,
            title
          ]
        ]
      else
        []
      end

    commands = multiplot_command ++ image_file_commands
    {image_file, commands}
  end

  # def draw_commands(implementation, arg_list, title, options \\ %{}) do
  #  {chart_commands, datasets} = collate_for_chart(implementation, arg_list)
  def draw_commands(chart_specs, title, options \\ %{}) do
    {chart_commands, datasets} = collate_for_image(chart_specs)

    {image_file, image_commands} = commands_for_image(title, options, Enum.count(chart_specs))

    {image_file, image_commands ++ chart_commands, datasets}
  end

  @spec draw(module(), [map()], iodata(), map()) :: {atom(), iodata()} | atom()
  def draw(implementation, arg_list, title, options \\ %{}) do
    {image_file, commands, datasets} = draw_commands([{implementation, arg_list}], title, options)

    case Gnuplot.plot(commands, datasets) do
      {:ok, _cmd} -> {:ok, image_file}
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end

  def draw_multi(chart_specs, title, options \\ %{}) do
    {image_file, commands, datasets} = draw_commands(chart_specs, title, options)

    commands |> IO.inspect()

    case Gnuplot.plot(commands, datasets) do
      {:ok, _cmd} -> {:ok, image_file}
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end

  def glab() do
    draw_multi(
      [
        {ImpactMap,
         [
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
         ]},
        {TimeSeries,
         [
           %{
             "start_impact" => %{"phi" => 0.5, "v" => 0.15},
             "params" => %{"omega" => 2.8, "sigma" => 0, "r" => 0.8}
           }

           # ,
           # %{
           #  "start_impact" => %{"phi" => 0.5, "v" => 0.15},
           #  "params" => %{"omega" => 2.8, "sigma" => 0.2, "r" => 0.8}
           # }
         ]}
      ],
      "test"
    )
  end
end
