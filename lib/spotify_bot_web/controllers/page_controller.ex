defmodule SpotifyBotWeb.PageController do
  use SpotifyBotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
