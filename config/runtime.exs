import Config

config :charlie, :elevenlabs, api_key: System.get_env("ELEVENLABS_API_KEY")
