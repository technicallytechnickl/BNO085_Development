defmodule Bno085.MixProject do
  use Mix.Project

  @version "0.0.1"
  @source_url "tbd"

  def project do
    [
      app: :bno085,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Interface with BNO085 9DOF IMU Fusion Device",
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      ]
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
      {:circuits_i2c, "~>2.1.0"},
      {:cerlc, "~> 0.2.1"},
      {:ex_doc, "~> 0.37.3", only: :docs}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSE",
        "mix.exs",
        "README.md"
      ],
      links: %{
        "Github" => @source_url,
        "Datasheet" => "https://www.ceva-ip.com/wp-content/uploads/BNO080_085-Datasheet.pdf"
      },
      licenses: ["GNU GPLv3"]
    ]
  end
end
