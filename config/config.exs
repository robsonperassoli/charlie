import Config

config :charlie, :elevenlabs, voice_id: "XrExE9yKIg1WjnnlVkGX"

config :nx, :default_backend, EXLA.Backend
config :exla, :default_client, :host
config :exla, :clients, host: [platform: :host]
