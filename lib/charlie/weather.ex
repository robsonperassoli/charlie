defmodule Charlie.Weather do
  @url "https://api.open-meteo.com/v1"

  def current(location, temp_unit, timezone) do
    %{lat: lat, lng: lng} = Charlie.Geocode.geocode(location)


    response =
      @url
      |> URI.parse()
      |> URI.append_path("/forecast")
      |> URI.append_query(
        URI.encode_query([
          {"latitude", lat},
          {"longitude", lng},
          {"current", "temperature_2m,apparent_temperature"},
          {"daily", "temperature_2m_max,temperature_2m_min"},
          {"timezone", timezone},
          {"forecast_days", 1},
          {"temperature_unit", temp_unit}
        ])
      )
      |> Req.get!()
      |> Map.get(:body)

    current_temp =
      "#{response["current"]["temperature_2m"]} #{response["current_units"]["temperature_2m"]}"

    current_apparent_temp =
      "#{response["current"]["apparent_temperature"]} #{response["current_units"]["apparent_temperature"]}"

    min_temp =
      "#{List.first(response["daily"]["temperature_2m_min"])} #{response["daily_units"]["temperature_2m_min"]}"

    max_temp =
      "#{List.first(response["daily"]["temperature_2m_max"])} #{response["daily_units"]["temperature_2m_max"]}"

    "Current temperature is #{current_temp}, feels like #{current_apparent_temp}. Min today is #{min_temp} and max #{max_temp}."
  end
end
