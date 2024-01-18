defmodule Redlock.Mixfile do
  use Mix.Project

  @version "1.0.18"

  def project do
    [
      app: :redlock,
      elixir: "~> 1.14",
      version: @version,
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :redix, :poolboy, :ex_hash_ring]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:redix, "~> 1.3"},
      {:poolboy, "~> 1.5"},
      {:fastglobal, "~> 1.0.0"},
      {:ex_hash_ring, "~> 3.0"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: docs_extras(),
      source_ref: "v#{@version}",
      source_url: "https://github.com/lyokato/redlock"
    ]
  end

  defp docs_extras do
    [
      "README.md": [title: "Readme"],
      "CHANGELOG.md": [title: "Changelog"]
    ]
  end

  defp package() do
    [
      description: "Redlock (Redis Distributed Lock) implementation",
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/lyokato/redlock",
        "Docs" => "https://hexdocs.pm/redlock"
      },
      maintainers: ["Lyo Kato"]
    ]
  end
end
