defmodule Redlock.Mixfile do
  use Mix.Project

  @version "1.0.15"

  def project do
    [
      app: :redlock,
      elixir: "~> 1.5",
      version: @version,
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :secure_random, :redix, :poolboy, :ex_hash_ring]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:redix, "~> 1.1.0"},
      {:poolboy, "~> 1.5"},
      {:fastglobal, "~> 1.0.0"},
      {:ex_hash_ring, "~> 3.0"},
      {:secure_random, "~> 0.5.1"}
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
