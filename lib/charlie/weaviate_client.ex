defmodule Charlie.WeaviateClient do
  @api_url "http://localhost:8080/v1"

  def create_object(class_name, properties, opts \\ []) do
    vector = Keyword.get(opts, :vector)

    Req.post!(@api_url <> "/objects",
      json: %{class: class_name, properties: properties, vector: vector}
    )
  end

  def create_class(class_name) do
    Req.post!(@api_url <> "/schema",
      json: %{
        "class" => class_name
      }
    )
  end

  def drop_class(class_name) do
    Req.delete!(@api_url <> "/schema/" <> class_name)
  end

  def search_episodic_memory(query) do
    vector =
      query
      |> Charlie.LocalLLM.embed()
      |> List.first()

    """
    {
      Get {
        EpisodicMemory(
          limit: 3
          hybrid: {
            query: "#{query}",
            vector: #{Jason.encode!(vector)}
          }
        ) {
          summary
          context_tags
          what_to_avoid
          what_worked
        }
      }
    }
    """
    |> graphql()
  end

  def graphql(query) do
    %Req.Response{body: body} = Req.post!(@api_url <> "/graphql", json: %{query: query})

    body["data"]
  end
end
