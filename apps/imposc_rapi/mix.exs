defmodule ImposcRapi.MixProject do
  use Mix.Project

  def project do
    [
      app: :imposc_rapi,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [flags: ["-Werror_handling", "-Wrace_conditions", "-Wunderspecs", "-Wno_match"]],
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ImposcRapi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:json, "~> 1.3"},
      {:dialyxir, "~> 0.4", only: [:dev]},
      {:plug, "~> 1.6"},
      {:cowboy, "~> 2.4"},
      {:plug_cowboy, "~> 2.0"},
      {:imposc, in_umbrella: true}
    ]
  end
end
