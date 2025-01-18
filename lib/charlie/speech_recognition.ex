defmodule Charlie.SpeechRecognition do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def transcribe(audio_path) do
    GenServer.call(__MODULE__, {:transcribe, audio_path}, 40_000)
  end

  @impl GenServer
  def init(_) do
    model = {:hf, "openai/whisper-base"}

    {:ok, whisper} = Bumblebee.load_model(model)
    {:ok, featurizer} = Bumblebee.load_featurizer(model)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(model)
    {:ok, generation_config} = Bumblebee.load_generation_config(model)

    serving =
      Bumblebee.Audio.speech_to_text_whisper(whisper, featurizer, tokenizer, generation_config,
        defn_options: [compiler: EXLA]
      )

    {:ok, serving}
  end

  @impl GenServer
  def handle_call({:transcribe, audio_path}, _from, serving) do
    result = Nx.Serving.run(serving, {:file, audio_path})
    {:reply, result, serving}
  end
end
