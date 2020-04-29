defmodule Tracex.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :tracex,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      main: "Tracex",
      extras: ["README.md"],
      source_url: "https://github.com/szajbus/tracex",
      source_ref: @version
    ]
  end

  defp package() do
    [
      description: "Static analysis for mix projects using compiler tracing.",
      maintainers: ["Michał Szajbe"],
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/szajbus/tracex"
      }
    ]
  end
end
