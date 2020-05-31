defmodule Imposc.MixProject do
  use Mix.Project

  def project do
    [
      app: :imposc,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      dialyzer: [flags: ["-Werror_handling", "-Wrace_conditions", "-Wunderspecs", "-Wno_match"]],
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock"
    ]
  end

  def escript do
    [main_module: CLI]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [default_outfile: "png"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnuplot, "~> 1.19"},
      {:json, "~> 1.3"},
      {:dialyxir, "~> 0.4", only: [:dev]}
    ]
  end
end
