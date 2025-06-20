defmodule QMI.MixProject do
  use Mix.Project

  @version "0.10.1"
  @source_url "https://github.com/nerves-networking/qmi"

  def project do
    [
      app: :qmi,
      version: @version,
      description: description(),
      package: package(),
      source_url: @source_url,
      elixir: "~> 1.14",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["mix_clean"],
      deps: deps(),
      dialyzer: [
        flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
      ],
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs,
        dialyzer: :lint,
        credo: :lint
      ]
    ]
  end

  defp description do
    "Qualcomm MSM Interface in Elixir"
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4.0", only: :lint, runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:elixir_make, "~> 0.6", runtime: false},
      {:credo, "~> 1.2", only: :lint, runtime: false},
      {:credo_binary_patterns, "~> 0.2.2", only: :lint, runtime: false}
    ]
  end

  def docs do
    [
      assets: %{"assets" => "assets"},
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_modules: [
        Services: [
          QMI.Control,
          QMI.DeviceManagement,
          QMI.NetworkAccess,
          QMI.WirelessData
        ],
        Codec: [
          QMI.Codec.Control,
          QMI.Codec.DeviceManagement,
          QMI.Codec.NetworkAccess,
          QMI.Codec.WirelessData
        ]
      ]
    ]
  end

  def package do
    [
      files: [
        "CHANGELOG.md",
        "c_src",
        "lib",
        "LICENSES/*",
        "mix.exs",
        "NOTICE",
        "README.md",
        "REUSE.toml",
        "Makefile"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" => "https://api.reuse.software/info/github.com/nerves-networking/qmi"
      }
    ]
  end
end
