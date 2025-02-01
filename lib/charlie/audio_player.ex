defmodule Charlie.AudioPlayer do
  @moduledoc """
  Membrane pipeline that will play an `.mp3` file.
  """

  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, path_to_mp3) do
    # Play 44.1k s24le 1ch mp3 files
    # Stream from file
    spec =
      child(:file, %Membrane.File.Source{location: path_to_mp3})
      # Decode frames
      |> child(:decoder, Membrane.MP3.MAD.Decoder)
      # # Convert Raw :s24le to Raw :s16le
      |> child(:converter, %Membrane.FFmpeg.SWResample.Converter{
        output_stream_format: %Membrane.RawAudio{
          sample_format: :s16le,
          sample_rate: 44100,
          channels: 1
        }
      })
      # Stream data into PortAudio to play it on speakers.
      |> child(:portaudio, Membrane.PortAudio.Sink)

    {[spec: spec], %{}}
  end

  # @impl true
  # def handle_init(_ctx, path_to_mp3) do
  #   # Play 16k s16le 1ch wav files
  #   # Stream from file
  #   spec =
  #     child(:file, %Membrane.File.Source{location: path_to_mp3})
  #     |> child(:decoder, Membrane.WAV.Parser)
  #     # Stream data into PortAudio to play it on speakers.
  #     |> child(:portaudio, Membrane.PortAudio.Sink)

  #   {[spec: spec], %{}}
  # end
end
