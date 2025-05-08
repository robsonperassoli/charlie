defmodule Charlie.Chat.Tools do
  alias Charlie.UserSettings

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
                  "The format to return the weather in, e.g. 'celsius' or 'fahrenheit', default to celsius",
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
          "arguments" => %{"location" => location} = args
        }
      }) do
    Charlie.Weather.current(
      location,
      args["format"] || UserSettings.temp_unit(),
      Charlie.UserSettings.timezone()
    )
  end

  def eval(%{
        "function" => %{
          "name" => "search_web",
          "arguments" => %{"subject" => subject}
        }
      }) do
    %{"results" => results} = Charlie.Search.search(subject)

    results
    |> Enum.take(5)
    |> Enum.map(
      &"""
      Source: #{Enum.join(&1["engines"], ", ")}
      Category: #{&1["category"]}
      Title: #{&1["title"]}
      Content: #{&1["content"]}
      """
    )
    |> Enum.join("\n\n")
  end
end
