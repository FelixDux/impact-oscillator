defmodule Imposc.MixProject do
  use Mix.Project

  def project do
    [
      app: :imposc,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnuplot, "~> 1.19"},
      {:json, "~> 1.3"}#,
#      {:yamerl, "~> 0.8"}
    ]
  end
end
