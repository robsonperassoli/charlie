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

  def test() do
    Charlie.WeaviateClient.drop_class("EpisodicMemory")
    |> dbg()

    Charlie.WeaviateClient.create_class("EpisodicMemory")
    |> dbg()

    embedding =
      """
      context tags: greeting, introduction
      summary: User introduced themselves and the assistant acknowledged with a greeting.
      what worked: Effective use of acknowledgment and mutual greetings.
      """
      |> Charlie.LocalLLM.embed()
      |> List.first()

    Charlie.WeaviateClient.create_object(
      "EpisodicMemory",
      %{
        "context_tags" => ["greeting", "introduction"],
        "summary" => "User introduced themselves and the assistant acknowledged with a greeting.",
        "what_to_avoid" => "N/A",
        "what_worked" => "Effective use of acknowledgment and mutual greetings."
      },
      vector: embedding
    )
    |> dbg()

    Charlie.WeaviateClient.search_episodic_memory("what is your name?")
    |> dbg()
  end
end
