defmodule Charlie.MixProject do
  use Mix.Project

  def project do
    [
      app: :charlie,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Charlie.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bumblebee, "~> 0.6.0"},
      {:nx, "~> 0.9.2"},
      {:exla, "~> 0.9.2"}
    ]
  end
end
