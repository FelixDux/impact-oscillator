defmodule PlotCommands do
  def chart_title(title) do
    [:set, :title, title]
  end

  @callback command_for_plot(iodata()) :: [any()]

  @callback from_args(map()) :: [any()]

  @callback data_for_plot(map()) :: {iodata(), [any()]}

  def collate_data(implementation, arg_list) do
    data =
      arg_list
      |> Enum.map(fn args ->
        Task.async(fn ->
          args |> implementation.data_for_plot
        end)
        |> (&Task.await(&1)).()
      end)

    0..1 |> Enum.map(fn i -> data |> Enum.map(&elem(&1, i)) end) |> List.to_tuple()
  end

  @spec draw(module(), [map()], iodata()) :: {atom(), iodata()} | atom()
  def draw(implementation, arg_list, title) do
    {labels, datasets} = collate_data(implementation, arg_list)

    commands =
      labels
      |> Enum.map(&implementation.command_for_plot(&1))
      |> (&[chart_title(title), Gnuplot.plots(&1)]).()

    # |> IO.inspect

    case Gnuplot.plot(commands, datasets) do
      {:ok, _cmd} -> :ok
      {:error, message} -> {:error, message}
      _ -> {:error, "Unknown error generating chart"}
    end
  end
end

