defmodule WikiexploreWeb.APIController do
  use WikiexploreWeb, :controller

  def index(conn, _params) do
    {:ok, body, conn} = read_body(conn)
    body = Jason.decode!(body, keys: :atoms)
    geojson = distance({body.latitude, body.longitude}, {body.south, body.longitude})
    |> get_nearby_places(body.latitude, body.longitude)
    |> wikipages_to_geojson()
    json(conn, geojson)
  end

  @doc """
  Shamelessly ripped off of here:
  https://github.com/acmeism/RosettaCodeData/blob/master/Task/Haversine-formula/Elixir/haversine-formula.elixir
  """
  def distance({lat1, long1}, {lat2, long2}) do
    dlat  = :math.sin((lat2 - lat1) * :math.pi / 360)
    dlong = :math.sin((long2 - long1) * :math.pi / 360)
    a = dlat * dlat + dlong * dlong * :math.cos(lat1 * :math.pi / 360) * :math.cos(lat2 * :math.pi / 360)
    6_371_008.7714 * 2 * :math.asin(:math.sqrt(a))
  end

  @doc """
  Takes a latitude, longitude, and radius, then outputs
  the a map of Wikipedia pages within the radius of that
  lat/lon using the Wikipedia mobile app technique
  """
  @spec get_nearby_places(number, number, number, integer) :: map
  def get_nearby_places(radius, lat, lng, entries \\ 20) do

    # I know there's a specific Wikipedia geosearch ability, but that's very limited in the fact that it can only search
    # in a maximum of 10km, which is very unhelpful for the scale I'm working on.
    # This is a neat workaround that allows searching for articles in a location of any size.
    params = [
      action: "query",
      format: "json",
      colimit: entries,
      generator: "search",
      prop: "coordinates|extracts",
      exintro: true,
      exlimit: "max",
      gsrsearch: "nearcoord:" <> to_string(round(radius)) <> "m," <> to_string(lat) <> "," <> to_string(lng),
      gsrlimit: entries
    ]

    HTTPoison.get!("https://en.wikipedia.org/w/api.php", [], params: params)
    |> HTTPoison.Handlers.Multipart.decode_body()
    |> Jason.decode!(keys: :atoms)
    |> Map.fetch!(:query)
    |> Map.fetch!(:pages)

  end

  @doc """
  Takes a Wikipedia API json-esque file, and converts it into the geoJson format
  """
  @spec wikipages_to_geojson(map) :: map
  def wikipages_to_geojson(json) do
    %{
      type: "FeatureCollection",
      features:
        Map.values(json)
        |> Enum.map(fn x ->
          Map.update!(x, :coordinates, fn y ->
            List.first(y)
            |> Map.drop([:globe, :primary])
            |> Map.values()
            |> Enum.reverse()
          end)
          |> (fn x ->
            %{
              geometry: %{coordinates: x.coordinates, type: "Point"},
              properties: %{pageid: x.pageid, title: x.title, extract: x.extract},
              type: "Feature"
            }
          end).()
        end)
    }
  end
end
