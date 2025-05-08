defmodule Charlie.Geocode do
  @url "https://nominatim.openstreetmap.org/search"

  def geocode(location) do
    response =
      @url
      |> URI.parse()
      |> URI.append_query(
        URI.encode_query([
          {"q", location},
          {"format", "jsonv2"}
        ])
      )
      |> Req.get!()
      |> Map.get(:body)
      |> List.first()

    %{lat: response["lat"], lng: response["lon"]}
  end
end
