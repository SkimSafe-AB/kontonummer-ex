defmodule Kontonummer.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :kontonummer,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [
        main: "Kontonummer",
        source_ref: "v#{@version}",
        source_url: "https://github.com/SkimSafe-AB/kontonummer-ex"
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
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "A library for validating Swedish bank account numbers."
  end

  defp package do
    [
      maintainers: ["Philip Mannheimer"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/SkimSafe-AB/kontonummer-ex"}
    ]
  end
end
