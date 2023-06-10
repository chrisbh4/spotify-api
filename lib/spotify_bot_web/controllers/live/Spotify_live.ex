defmodule SpotifyBotWeb.SpotifyLive do
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    ~H"""
      <h1>Spotify API access point </h1>
      <button phx-click="click-me">Access API </button>
      <button phx-click="fetch-artist">Fetch artist data </button>
    """
  end


  def mount(_params, _ , socket) do
    {:ok, socket}
  end




  def handle_event("click-me",_params , socket) do
    command = "curl"
    args = [
      "-X", "POST",
      "https://accounts.spotify.com/api/token",
      "-H", "Content-Type: application/x-www-form-urlencoded",
      "-d", "grant_type=client_credentials&client_id=ae9e634bde02464480b62fa124143558&client_secret=b647f587af054503a8b96c5e1c890607"
    ]

    case System.cmd(command, args) do
      {output, 0} ->
        # Extract the access token from the output (assuming it's in JSON format)
        access_token = Jason.decode!(output)["access_token"]

        # Do something with the access token
        # ...
        socket = assign(socket, spotify_access_token: access_token)
        Logger.info(spotify_access_token: socket.assigns.spotify_access_token)
        {:noreply, socket}

      {_, _} ->
        # Handle command execution errors
        {:error, "Failed to execute the curl command."}
    end
  end

  def handle_event("fetch-artist", _params, socket) do
    # Willie's url: "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY?si=aQ82WY_SS4OfwWYMAQBm_A"

    Logger.info(fetch: socket.assigns)
    command = "curl"
    args = [
      "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY?si=aQ82WY_SS4OfwWYMAQBm_A",
      "-H", "Authorization: Bearer #{socket.assigns.spotify_access_token}"
    ]

    case System.cmd(command, args) do
      {output, 0} ->
        # Process the output (e.g., parse JSON, extract relevant data)
        # ...
        Logger.info(output: output)
        {:noreply, socket}

      {_, _} ->
        # Handle command execution errors
        {:error, "Failed to execute the curl command."}
    end

  end


# * HTTPoision libary
  # def handle_event("btn-click", _, socket) do
  #   case HTTPoison.get(url) do
  #     {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
  #       IO.puts body
  #     {:ok, %HTTPoison.Response{status_code: 404}} ->
  #       IO.puts "Not found :("
  #     {:error, %HTTPoison.Error{reason: reason}} ->
  #       IO.inspect reason
  #   end

  #   {:noreply, socket}
  # end

end
