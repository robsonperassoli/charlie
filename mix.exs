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
      {:exla, "~> 0.9.2"},
      {:membrane_core, "~> 1.1"},
      {:membrane_portaudio_plugin, "~> 0.19"},
      {:membrane_file_plugin, "~> 0.17.2"},
      {:membrane_ffmpeg_swresample_plugin, "~> 0.20.2"},
      {:membrane_wav_plugin, "~> 0.10.1"},
      {:membrane_mp3_mad_plugin, "~> 0.18.4"},
      {:req, "~> 0.5"}
    ]
  end
end
