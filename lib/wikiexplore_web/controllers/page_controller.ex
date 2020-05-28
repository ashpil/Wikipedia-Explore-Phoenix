defmodule WikiexploreWeb.PageController do
  use WikiexploreWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
