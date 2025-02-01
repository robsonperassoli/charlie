defmodule Charlie do
  @moduledoc """
  Documentation for `Charlie`.
  """

  require Logger

  def record() do
    audio_file = System.tmp_dir!() <> "/chunk_#{System.system_time(:second)}.wav"
    {:ok, _sup, pipeline} = Membrane.Pipeline.start_link(Charlie.AudioRecorder, audio_file)

    Process.sleep(4000)

    Membrane.Pipeline.terminate(pipeline)

    Logger.info("audio recorded")

    %{chunks: chunks} = Charlie.SpeechRecognition.transcribe(audio_file)

    text =
      chunks
      |> Enum.map(& &1[:text])
      |> Enum.join(" ")

    Logger.info("Transcribed input audio into text: #{text}")

    llm_resp = Charlie.LocalLLM.prompt(text)

    Logger.info("""
    Prompted llm with text: #{text}.
    Got response: #{llm_resp}
    """)

    {:ok, charlie_voice_file} = Charlie.TextToSpeech.convert(llm_resp)

    Logger.info("Converted text into matilda's voice")

    {:ok, _sup, _pipeline} = Membrane.Pipeline.start_link(Charlie.AudioPlayer, charlie_voice_file)
  end
end
