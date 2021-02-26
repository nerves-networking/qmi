defmodule Qmi.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/smartrent/qmi"

  def project do
    [
      app: :qmi,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      ]
    ]
  end

  def application do
    [
      mod: {QMI.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:elixir_make, "~> 0.6", runtime: false}
    ]
  end

  def docs do
    [
      assets: "assets",
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: [
        "lib",
        "src",
        "CHANGELOG.md",
        "LICENSE",
        "mix.exs",
        "README.md"
      ]
    ]
  end
end
