defmodule EllipseAction do
  @behaviour Action
  
  @doc """
  Generates a (1, n) orbit sigma response plot using arguments initialised from `:args`.
  """
  @impl Action
  def execute(args) do
    args
    |> (&Curves.sigma_ellipse(
          CoreWrapper.from_args(Integer, &1, "n"),
          CoreWrapper.from_args(Float, &1, "omega"),
          CoreWrapper.from_args(Float, &1, "r"),
          CoreWrapper.from_args(Integer, &1, "num_points")
        )).()
  end
end
