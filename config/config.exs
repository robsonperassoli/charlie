import Config

config :nx, :default_backend, EXLA.Backend
config :exla, :default_client, :host
config :exla, :clients, host: [platform: :host]
