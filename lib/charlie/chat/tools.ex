defmodule Charlie.Chat.Tools do
  def available_tools() do
    [
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
      },
      %{
        type: "function",
        function: %{
          name: "search_web",
          description: "Search for a given subject on a search engine",
          parameters: %{
            type: "object",
            properties: %{
              subject: %{
                type: "string",
                description: "the subject to search for, e.g. latest news in San Francisco"
              }
            },
            required: ["subject"]
          }
        }
      }
    ]
  end

  def eval(%{
        "function" => %{
          "name" => "get_current_weather",
          "arguments" => %{"format" => format, "location" => location}
        }
      }) do
    get_current_weather(location, format)
  end

  def eval(%{
        "function" => %{
          "name" => "search_web",
          "arguments" => %{"subject" => subject}
        }
      }) do
    """
    ### #{subject}
    Riot in Sao Paulo, AI nerds are going crazy

    ### #{subject}
    Brazil won the 2025 world cup
    """
  end

  def get_current_weather(location, format) do
    "55"
  end
end
