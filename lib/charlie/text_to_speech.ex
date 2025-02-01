defmodule Charlie.TextToSpeech do
  @v1_api_url "https://api.elevenlabs.io/v1"

  def convert(text) do
    api_key = Application.get_env(:charlie, :elevenlabs)[:api_key]
    voice_id = Application.get_env(:charlie, :elevenlabs)[:voice_id]

    %Req.Response{body: body} =
      Req.post!("#{@v1_api_url}/text-to-speech/#{voice_id}",
        json: %{
          text: text,
          # output_format: "pcm_16000",
          model_id: "eleven_multilingual_v2"
        },
        headers: %{
          "xi-api-key" => api_key
        },
        connect_options: [
          timeout: 20_000
        ],
        receive_timeout: 20_000,
        pool_timeout: 10_000
      )

    file = "#{System.tmp_dir!()}/charlie-#{System.system_time(:second)}.wav"
    File.write!(file, body)

    {:ok, file}
  end
end
