defmodule Charlie.Search do
  @searxng_url "http://localhost:8081/search"

  def search(query) do
    @searxng_url
    |> URI.parse()
    |> URI.append_query(URI.encode_query([{"format", "json"}, {"q", query}]))
    |> Req.get!()
    |> Map.get(:body)
  end
end
