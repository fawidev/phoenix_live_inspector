defmodule PhoenixLiveInspector.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :phoenix_live_inspector,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/fawidev/phoenix_live_inspector"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PhoenixLiveInspector.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:telemetry, "~> 1.2"},
      {:jason, "~> 1.4"},
      {:websock_adapter, "~> 0.5"},
      {:plug_cowboy, "~> 2.6"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Phoenix LiveView Inspector - Real-time debugging and state inspection for LiveView applications."
  end

  defp package do
    [
      maintainers: ["Fawad Ahsan"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/fawidev/phoenix_live_inspector",
        "Hex" => "https://hex.pm/packages/phoenix_live_inspector",
        "Docs" => "https://hexdocs.pm/phoenix_live_inspector"
      },
      files: ~w(lib browser_extension mix.exs README.md LICENSE CONTRIBUTING.md)
    ]
  end

  defp docs do
    [
      main: "PhoenixLiveInspector",
      name: "Phoenix LiveView Inspector",
      source_ref: "v#{@version}",
      source_url: "https://github.com/fawidev/phoenix_live_inspector",
      homepage_url: "https://hex.pm/packages/phoenix_live_inspector",
      extras: [
        "README.md"
      ]
    ]
  end
end