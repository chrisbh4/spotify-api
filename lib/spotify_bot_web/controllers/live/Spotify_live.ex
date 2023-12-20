defmodule SpotifyBotWeb.SpotifyLive do
  # alias ElixirLS.LanguageServer.Providers.FoldingRange.Token
  # alias ElixirSense.Log
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    ~H"""

      <h1>Spotify API access point </h1>
      <button phx-click="fetch-token">Generate Token </button>
      <button phx-click="fetch-artist">Artist data </button>
      <button phx-click="fetch-top-tracks">Top Tracks </button>
      <button phx-click="fetch-playlist"> Demo Playlist</button>
      <button phx-click="play-music">Play Music </button>
      <%!-- <button phx-click="play-song">Play music </button> --%>


      <iframe
        title="DEMO Player "
        src={"https://open.spotify.com/embed/playlist/30GBe73yDNLqPBi6fJlUAi?utm_source=generator&theme=0"}
        width="100%"
        height="100%"
        class="h-auto w-1/2"
        frameBorder="0"
        allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"
        loading="lazy"
      />



      <%!-- <figure>
        <figcaption>Listen to the T-Rex:</figcaption>
          <audio
              controls
              src="/media/cc0-audio/t-rex-roar.mp3">
          </audio>
      </figure> --%>
    """
  end

  def mount(_params, _, socket) do
    {:ok, socket}
  end


  def timer_func() do
    :erlang.start_timer(2000, self(), :fetch_token)
  end


  def handle_info(:fetch_token, socket) do
    Logger.info("Timer Info called")
    {:noreply, socket}
  end
# So why is the timer pattern matching on :timeout and not :fetch_token??
  # Is that how start_timer works or am I missing something (need to read the docs more)
  def handle_info({:timeout, data, :fetch_token}, socket) do
    Logger.info(':timeout')
    IO.inspect(data)
    {:noreply, socket}
  end

  def handle_event("fetch-token", _params, socket) do
  url = "https://accounts.spotify.com/api/token"
  scopes = "streaming user-read-email user-read-private user-read-playback-state user-read-recently-played user-modify-playback-state"
  body = "grant_type=client_credentials&client_id=#{System.get_env("CLIENT_ID")}&client_secret=#{System.get_env("CLIENT_SECRET")}&scope=#{scopes}"
  headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

  timer_func()

  res = HTTPoison.post(url, body, headers)
  case res do
    {:ok , %{status_code: 200, body: body}} ->
      Logger.info("Token fetched ✅")
      json_data = Jason.decode!(body)
      {:noreply, assign(socket, :access_token, json_data["access_token"])}

    {:ok, %{status_code: status_code, body: body}} ->
      Logger.info(status_code: status_code)
      Logger.info(body: body)
      {:noreply, socket}

    {:error, error} ->
      Logger.info(error)
      {:noreply, socket}
    end
  end

  def handle_event("fetch-artist", _params, socket) do
    # Willie
    # url = "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY?si=aQ82WY_SS4OfwWYMAQBm_A"
    url = "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY"
    # url = "https://api.spotify.com/v1/artists/3TVXtAsR1Inumwj472S9r4"
    res = HTTPoison.get(url, [{"Authorization:", "Bearer #{socket.assigns.access_token}"}] )

    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("200")
        IO.inspect(Jason.decode!(body))
        {:noreply, socket}

        {:ok, %{status_code: status_code, body: body}} ->
          Logger.info("Artist data cannot be fetched")
          Logger.info(status_code: status_code)
          Logger.info(body: body)
          IO.inspect(Jason.decode!(body))
        {:noreply, socket}

      {:error , error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  def handle_event("fetch-top-tracks", _params, socket) do
    url = "https://api.spotify.com/v1/artists/3TVXtAsR1Inumwj472S9r4/top-tracks?country=US"
    res = HTTPoison.get(url, [{"Authorization:", "Bearer #{socket.assigns.access_token}"}] )

    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("200")
        IO.inspect(Jason.decode!(body))
        {:noreply, socket}

        {:ok, %{status_code: status_code, body: body}} ->
          Logger.info("Artist data cannot be fetched")
          Logger.info(status_code: status_code)
          Logger.info(body: body)
          IO.inspect(Jason.decode!(body))
        {:noreply, socket}

      {:error , error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  def handle_event("fetch-playlist", _params, socket) do
    url = "https://api.spotify.com/v1/playlists/30GBe73yDNLqPBi6fJlUAi"
    res = HTTPoison.get(url, [{"Authorization:", "Bearer #{socket.assigns.access_token}"}] )

    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("200")
        IO.inspect(Jason.decode!(body))
        {:noreply, socket}

        {:ok, %{status_code: status_code, body: body}} ->
          Logger.info("Playlist data: cannot be fetched")
          Logger.info(status_code: status_code)
          IO.inspect(Jason.decode!(body))
        {:noreply, socket}

      {:error , error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  # *Try to use HTTPoision libary to be able to stream but I need the 'Album URI' to be able to get the track I want to play
  #  HTTPoision libary
  def handle_event("play-music", _params, socket) do
    headers = [
      {"Authorization", "Bearer #{socket.assigns.access_token}"},
      {"Content-Type", "application/json"}
    ]

    body = '{
      "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      "offset": {
          "position": 5
      },
      "position_ms": 0
  }'

#! (CaseClauseError) no case clause matching: %{offset: %{position: 5}, context_uri: "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr", position_ms: 0}
#   body = %{
#     context_uri: "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
#     offset: %{
#         position: 5
#     },
#     position_ms: 0
# }

    url = "https://api.spotify.com/v1/me/player/play"

    res = HTTPoison.put(url, body, headers)

    case res do
      {:ok , %{status_code: 200, body: body}} ->
        IO.inspect(body)
        {:noreply, socket}

      {:ok, %{status_code: status_code}} ->
        Logger.info('#{status_code}')
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
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

  # Basic attempt
  def handle_event("curl-cmd-play-song", _, socket) do
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

end
