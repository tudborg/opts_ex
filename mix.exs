defmodule Opts.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/tudborg/opts_ex"

  def project do
    [
      name: "Opts",
      source_url: @source_url,
      app: :opts,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      dialyzer: dialyzer(),
      test_coverage: test_coverage(),
      aliases: aliases(),
      cli: cli()
    ]
  end

  def cli do
    [preferred_envs: [check: :test]]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "credo suggest --all --format=oneline",
        "test --cover --slowest 5"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.33", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      flags: [
        :error_handling,
        :underspecs,
        :unmatched_returns,
        :no_return
      ]
    ]
  end

  defp description do
    """
    A utility to increase ergonomics when working with Keyword lists.
    """
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "Opts",
      # logo: "path/to/logo.png",
      extras: ["README.md"]
    ]
  end

  defp test_coverage() do
    [
      summary: [threshold: 85]
    ]
  end
end
