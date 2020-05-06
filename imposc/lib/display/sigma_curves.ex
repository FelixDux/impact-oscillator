
defmodule SigmaCurves do
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
                      "{/Symbol s}-response curve for (1, #{n}) orbits for {/Symbol w} = #{omega}, r = #{
                        r
                      }"
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
