defmodule MultiplotAction do
  @behaviour Action

  @moduledoc """
  Generates multiple plots on a single image
  """

  @impl Action
  def expects_list?() do
    true
  end

  @doc """
  Generates multiple plots on a single image using arguments initialised from `:args`.

  `:options` specifies available options, including a title for the image and whether output is to be directed to a file instead of to the terminal.
  """
  @impl Action
  def execute(args, options) do
    args
    |> IO.inspect()
    |> Enum.map(fn arg ->
      Map.to_list(arg)
      |> (&(with [head | _] <- &1,
                 {module_name, arg_list} <- head,
                 {:ok, module} <- PlotCommands.multiplot_implementation(module_name) do
              {ActionMap.get_module(module), arg_list}
            end)).()
    end)
    |> IO.inspect()
    |> PlotCommands.draw_multi(options)
  end

  @doc """
  Specifies the arguments required for the available plots 
  """
  @impl Action
  def requirements() do
    ActionMap.list_actions()
    |> Enum.filter(fn {action, _description} ->
      action != "multiplot"
    end)
    |> Enum.map(fn {action, _description} ->
      %{action => ActionMap.requirements(action)}
    end)
  end

  @doc """
  Specifies the options available for the action
  """
  @impl Action
  def expected_options() do
    %{"title" => nil, "outfile" => nil}
  end

  @doc """
  Returns a description of the action
  """
  @impl Action
  def description() do
    @moduledoc
  end
end
