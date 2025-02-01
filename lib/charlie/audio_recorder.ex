defmodule Charlie.AudioRecorder do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, output_audio) do
    spec =
      child(:source, %Membrane.PortAudio.Source{
        # nil means default input device
        device_id: :default,
        latency: :low,
        sample_format: :s16le,
        # Whisper expects 16kHz
        sample_rate: 16_000,
        # mono
        channels: 1
      })
      # |> child(:converter, %Membrane.FFmpeg.SWResample.Converter{
      #   input_stream_format: %Membrane.RawAudio{
      #     channels: 1,
      #     sample_rate: 16_000,
      #     sample_format: :s16le
      #   },
      #   output_stream_format: %Membrane.RawAudio{
      #     channels: 2,
      #     sample_rate: 48_000,
      #     sample_format: :s16le
      #   }
      # })
      |> child(:serializer, Membrane.WAV.Serializer)
      |> child(:sink, %Membrane.File.Sink{
        location: output_audio
      })

    {[spec: spec], %{}}
  end

  def start_recording do
    {:ok, sup, pipeline} = Membrane.Pipeline.start_link(Charlie.AudioRecorder)
    # Membrane.Pipeline.
    {:ok, pipeline}
  end

  def stop_recording(pipeline) do
    Membrane.Pipeline.terminate(pipeline)
  end
end
