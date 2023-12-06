defmodule SpotifyBotWeb.SpotifyLive do
  alias ElixirSense.Log
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    ~H"""
      <h1>Spotify API access point </h1>
      <button phx-click="play-poison">Poison Fetch </button>
      <button phx-click="click-me">Access API </button>
      <button phx-click="fetch-artist">Fetch artist data </button>
      <button phx-click="play-song">Play music </button>
      <figure>
        <figcaption>Listen to the T-Rex:</figcaption>
          <audio
              controls
              src="/media/cc0-audio/t-rex-roar.mp3">
          </audio>
      </figure>
    """
  end

  def mount(_params, _, socket) do
    {:ok, socket}
  end

  def handle_event("click-me", _params, socket) do
    command = "curl"

    # args = [
    #   "-X",
    #   "POST",
    #   "https://accounts.spotify.com/api/token",
    #   "-H",
    #   "Content-Type: application/x-www-form-urlencoded",
    #   "-d",
    #   "grant_type=client_credentials&client_id=47b6547d58be4b5199a2d6ffdced8d39&client_secret=0672593b84b84b58aa550f6124cc4b8f"
    # ]

    args = [
      "-X",
      "POST",
      "https://accounts.spotify.com/api/token",
      "-H",
      "Content-Type: application/x-www-form-urlencoded",
      "-d",
      "grant_type=client_credentials&client_id=47b6547d58be4b5199a2d6ffdced8d39&client_secret=0672593b84b84b58aa550f6124cc4b8f",
      "-d",
      "scope=streaming user-read-email user-read-private"
  ]

    case System.cmd(command, args) do
      {output, 0} ->

        # Extract the access token from the output (assuming it's in JSON format)
        access_token = Jason.decode!(output)["access_token"]
        Logger.info(JSON: Jason.decode!(output))
        Logger.info(access_token: access_token)
        socket = assign(socket, access_token: access_token)
        {:noreply, socket}

      {_, _} ->
        # Handle command execution errors
        {:error, "Failed to execute the curl command."}
    end
  end

  def handle_event("fetch-artist", _params, socket) do
    # Willie's(Moïses) url: "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY?si=aQ82WY_SS4OfwWYMAQBm_A"

    command = "curl"

    # args = [
    #   "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY?us=aQ82WY_SS4OfwWYMAQBm_A/albums",
    #   "-H",
    #   "Authorization: Bearer #{socket.assigns.access_token}"
    # ]

    # https://open.spotify.com/album/6CvBb1XqN0igtQrWrbXD80?si=6b0cJUssSFa76Md0uBUu3A
    args = [
      "https://api.spotify.com/v1/album/6CvBb1XqN0igtQrWrbXD80?si=6b0cJUssSFa76Md0uBUu3A",
      "-H",
      "Authorization: Bearer #{socket.assigns.access_token}"
    ]

    case System.cmd(command, args) do
      {output, 0} ->
        json = Jason.decode!(output)
        Logger.info(json)
        socket = assign(socket, artist_data: output)
        {:noreply, socket}

      {_, _} ->
        # Handle command execution errors
        {:error, "Failed to execute the curl command."}
    end
  end

  def handle_event("play-song", _, socket) do
    access_token = socket.assigns.access_token
    album_uri = "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr"
    position = 5
    position_ms = 0

    command = "curl"

    args = [
      "--request",
      "PUT",
      "--url",
      "https://api.spotify.com/v1/me/player/play",
      "--header",
      "Authorization: Bearer #{access_token}",
      "--header",
      "Content-Type: application/json",
      "--data",
      "{\"context_uri\": \"#{album_uri}\", \"offset\": {\"position\": #{position}}, \"position_ms\": #{position_ms}}"
    ]

    case System.cmd(command, args) do
      {output, 0} ->
        Logger.info(Song_Played: output)
        {:noreply, socket}

      {_, _} ->
        # Handle command execution errors
        {:error, "Failed to execute the curl command to play the song."}
    end
  end

  def handle_event("pause-song", _, socket) do
    access_token = socket.assigns.access_token

    command = "curl"

    args = [
      "--request",
      "PUT",
      "--url",
      "https://api.spotify.com/v1/me/player/pause",
      "--header",
      "Authorization: Bearer #{access_token}"
    ]

    case System.cmd(command, args) do
      {_, 0} ->
        # Successful execution, do something if needed
        {:noreply, socket}

      {_, _} ->
        # Handle command execution errors
        {:error, "Failed to execute the curl command to pause the song."}
    end
  end

  # *Try to use HTTPoision libary to be able to stream but I need the 'Album URI' to be able to get the track I want to play
  #  HTTPoision libary
  def handle_event("play-poison", _, socket) do
    headers = [
      {"Authorization", "Bearer #{socket.assigns.access_token}"},
      {"Content-Type", "application/json"}
    ]

    payload = %{
      # "context_uri" => album_uri,
      "context_uri" => socket.assigns.album_uri,
      # "offset" => %{"position" => position},
      "offset" => %{"position" => 0},
      "position_ms" => 0
    }


    url = "https://api.spotify.com/v1/me/player/play"
    case HTTPoison.put(url, payload, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, body}

      {:error, reason} ->
        {:error, reason}
    end

    {:noreply, socket}
  end



end
