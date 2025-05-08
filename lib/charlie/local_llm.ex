defmodule Charlie.LocalLLM do
  @base_url "http://localhost:11434"
  @default_model "qwen2.5:7b-instruct-q4_K_M"
  # @default_model "qwen2.5:3b-instruct-q4_K_M"
  # @default_model "deepseek-r1:8b"

  @default_embedding_model "nomic-embed-text"

  defmodule Message do
    @derive Jason.Encoder
    defstruct [:role, :content, :tool_calls]
  end

  def default_system_prompt(),
    do: """
    You are an AI personal assistant and you goal is to help answer questions as best as you can.
    """

  def prompt(text, opts \\ []) do
    model = Keyword.get(opts, :model, @default_model)
    system = Keyword.get(opts, :system)
    format = Keyword.get(opts, :format)

    %Req.Response{body: body} =
      Req.post!("#{@base_url}/api/generate",
        json: %{
          model: model,
          system: system,
          prompt: text,
          stream: false,
          format: format
        }
      )

    body["response"]
  end

  def chat([%Message{} | _] = messages, opts \\ []) do
    model = Keyword.get(opts, :model, @default_model)
    tools = Keyword.get(opts, :tools)
    into = Keyword.get(opts, :into)

    %Req.Response{body: body} =
      Req.post!("#{@base_url}/api/chat",
        json: %{
          model: model,
          messages: messages,
          stream: not is_nil(into),
          tools: tools
        },
        into: into,
        receive_timeout: 200_000
      )

    body
  end

  def embed(text, opts \\ []) do
    model = Keyword.get(opts, :model, @default_embedding_model)

    %Req.Response{body: body} =
      Req.post!("#{@base_url}/api/embed",
        json: %{
          model: model,
          input: text
        }
      )

    body["embeddings"]
  end

  def test_chat() do
    %Req.Response{body: body} =
      Req.post!("http://localhost:11434/api/chat",
        json: %{
          model: "mistral:7b-instruct-v0.3-q4_K_M",
          # model: "llama3:8b-instruct-q4_K_M",
          messages: [
            %{
              role: "system",
              content:
                "You are Charlie, a personal AI assistant and you goal is to help answer questions as best as you can."
            },
            %{role: "user", content: "what is you name?"},
            %{
              role: "assistant",
              content:
                " My name is Charlie, your personal AI assistant. How can I assist you today?"
            },
            %{role: "user", content: "how is the weather today in paris?"}
          ],
          stream: false
        }
      )

    body
  end

  def test_stream() do
    %Req.Response{body: body} =
      Req.post!("#{@base_url}/api/chat",
        json: %{
          model: "deepseek-r1:1.5b",
          # model: "llama3:8b-instruct-q4_K_M",
          messages: [
            %{
              role: "system",
              content:
                "You are Charlie, a personal AI assistant and you goal is to help answer questions as best as you can."
            },
            %{role: "user", content: "what is you name?"},
            %{
              role: "assistant",
              content:
                " My name is Charlie, your personal AI assistant. How can I assist you today?"
            },
            %{role: "user", content: "how is the weather today in paris?"}
          ],
          stream: true
        },
        into: IO.stream()
      )

    body
  end

  def test() do
    tools = [
      %{
        type: "function",
        function: %{
          name: "get_current_weather",
          description: "Get the current weather for a location",
          parameters: %{
            type: "object",
            properties: %{
              location: %{
                type: "string",
                description: "The location to get the weather for, e.g. San Francisco, CA"
              },
              format: %{
                type: "string",
                description:
                  "The format to return the weather in, e.g. 'celsius' or 'fahrenheit'",
                enum: ["celsius", "fahrenheit"]
              }
            },
            required: ["location", "format"]
          }
        }
      }
    ]

    %Req.Response{body: body} =
      Req.post!("http://localhost:11434/api/chat",
        json: %{
          model: "qwen2.5-coder:14b-instruct-q4_K_M",
          # model: "gemma2:9b-instruct-q4_K_M",
          messages: [
            %{
              role: "system",
              content:
                "You are Charlie, a personal AI assistant and you goal is to help answer questions as best as you can."
            },
            %{role: "user", content: "what is you name?"},
            %{
              role: "assistant",
              content:
                " My name is Charlie, your personal AI assistant. How can I assist you today?"
            },
            %{role: "user", content: "how is the weather today in paris and san francisco?"},
            %{
              role: "assistant",
              content: "",
              tool_calls: [
                %{
                  "function" => %{
                    "arguments" => %{"format" => "celsius", "location" => "Paris"},
                    "name" => "get_current_weather"
                  }
                },
                %{
                  "function" => %{
                    "arguments" => %{
                      "format" => "fahrenheit",
                      "location" => "San Francisco"
                    },
                    "name" => "get_current_weather"
                  }
                }
              ]
            },
            %{
              role: "tool",
              content: "24",
              tool_calls: [
                %{
                  "function" => %{
                    "arguments" => %{"format" => "celsius", "location" => "Paris"},
                    "name" => "get_current_weather"
                  }
                }
              ]
            },
            %{
              role: "tool",
              content: "80",
              tool_calls: [
                %{
                  "function" => %{
                    "arguments" => %{
                      "format" => "fahrenheit",
                      "location" => "San Francisco"
                    },
                    "name" => "get_current_weather"
                  }
                }
              ]
            }
          ],
          stream: false,
          tools: tools
        }
      )

    body
  end
end
