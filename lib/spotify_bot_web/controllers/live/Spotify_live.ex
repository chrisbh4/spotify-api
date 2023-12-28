defmodule SpotifyBotWeb.SpotifyLive do
  # alias ElixirLS.LanguageServer.Providers.FoldingRange.Token
  # alias ElixirSense.Log
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    ~H"""
      <div class='flex justify-center w-full bg-red-500 '>
      <h1>Spotify API access point </h1>
      <button phx-click="auth-flow">Auth Redirect </button>
      <button phx-click="fetch-token">Generate Token </button>
      <button phx-click="refresh-token">Refresh Token </button>
      <button phx-click="get-player">Get Play </button>
      <%!-- <button phx-click="start-timer">Start Timer </button>
      <button phx-click="fetch-artist">Artist data </button>
      <button phx-click="fetch-top-tracks">Top Tracks </button>
      <button phx-click="fetch-playlist"> Demo Playlist</button> --%>
      <button phx-click="play-music">Play Music </button>
      <%!-- <button phx-click="play-song">Play music </button> --%>
      </div>

      <%!-- <iframe
        title="DEMO Player "
        src={"https://open.spotify.com/embed/playlist/30GBe73yDNLqPBi6fJlUAi?utm_source=generator&theme=0"}
        width="100%"
        height="100%"
        class="h-auto w-1/2"
        frameBorder="0"
        allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"
        loading="lazy"
      /> --%>

      <%!-- <figure>
        <figcaption>Listen to the T-Rex:</figcaption>
          <audio
              controls
              src="/media/cc0-audio/t-rex-roar.mp3">
          </audio>
      </figure> --%>
    """
  end
  # https://developer.spotify.com/documentation/web-api/tutorials/code-flow
  # https://community.spotify.com/t5/Spotify-for-Developers/Invalid-username-cant-get-devices/td-p/5193469
  # https://developer.spotify.com/documentation/web-api/reference/get-a-users-available-devices

  def mount(params, _, socket) do
    case params["code"] do
      nil ->
        Logger.info("No code")
        socket = assign(socket, code: nil, state: nil)
        {:ok, socket}

      _ ->
        Logger.info("Mounting with code")
        socket = assign(socket, code: params["code"], state: params["state"])
        {:ok, socket}
    end
  end


  def handle_event("auth-flow", _params, socket) do
    url = "https://accounts.spotify.com/authorize?"
    redirect_uri = "http://localhost:4000"
    scope = "user-read-email user-read-private user-read-playback-state user-read-recently-played user-modify-playback-state streaming"
    state = for _ <- 1..16, into: "", do: <<Enum.random('0123456789abcdef')>>


    query_params = [
      response_type: "code",
      client_id: System.get_env("CLIENT_ID"),
      scope: scope,
      redirect_uri: redirect_uri,
      state: state
    ]
    |> URI.encode_query()

    res = HTTPoison.get("#{url}#{query_params}")

    # if headers comes back and contains "request_url" or "location" then do a fetch get request and see what the body or res contains
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Auth successful ✅")
        json_data = Jason.decode!(body)
        IO.inspect(json_data)
        {:noreply, socket}


      {:ok, %{status_code: status_code, body: _body, request_url: request_url}} ->
        Logger.info(status_code: status_code)
        Logger.info(request_url)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
      end
  end

# Authorization Code Flow fetch token
  def handle_event("fetch-token", _params, socket) do
    # IO.inspect(token_code: socket.assigns.code)
    url = "https://accounts.spotify.com/api/token"
    body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=http://localhost:4000"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]

    res = HTTPoison.post(url, body, headers)
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Auth Token Code fetched ✅")
        json_data = Jason.decode!(body)
        {:noreply, assign(socket, access_token: json_data["access_token"], expires_in: json_data["expires_in"], refresh_token: json_data["refresh_token"])}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info(status_code: status_code)
        Logger.info(body: body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
      end
  end

  def handle_event("refresh-token", _params, socket) do
    IO.inspect(socket.assigns.access_token)
    url = "https://accounts.spotify.com/api/token"
    # body = "grant_type=refresh_token&refresh_token=#{socket.assigns.refresh_token}&client_id=#{System.get_env("CLIENT_ID")}"
    body = "grant_type=refresh_token&refresh_token=#{socket.assigns.refresh_token}"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]
    # body = %{grant_type: "refresh_token", refresh_token: refresh_token, client_id: System.get_env("CLIENT_ID")}

    res = HTTPoison.post(url, body, headers)
    # IO.inspect(res)

    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Refreshed Token ✅")
        json_data = Jason.decode!(body)
        {:noreply, assign(socket, access_token: json_data["access_token"], expires_in: json_data["expires_in"])}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info(status_code: status_code)
        Logger.info(body: body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
      end
  end

# Client Credential Auth Flow
  # def handle_event("fetch-token", _params, socket) do
  #   url = "https://accounts.spotify.com/api/token"
  #   scope = "streaming user-read-email user-read-private user-read-playback-state user-read-recently-played user-modify-playback-state"
  #   body = "grant_type=client_credentials&client_id=#{System.get_env("CLIENT_ID")}&client_secret=#{System.get_env("CLIENT_SECRET")}&scope=#{scope}"
  #   headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

  #   res = HTTPoison.post(url, body, headers)
  #   case res do
  #     {:ok , %{status_code: 200, body: body}} ->
  #       Logger.info("Token fetched ✅")
  #       json_data = Jason.decode!(body)
  #       {:noreply, assign(socket, access_token: json_data["access_token"], expires_in: json_data["expires_in"])}

  #     {:ok, %{status_code: status_code, body: body}} ->
  #       Logger.info(status_code: status_code)
  #       Logger.info(body: body)
  #       {:noreply, socket}

  #     {:error, error} ->
  #       Logger.info(error)
  #       {:noreply, socket}
  #     end
  # end

  def handle_event("fetch-artist", _params, socket) do
    # Willie
    # url = "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY?si=aQ82WY_SS4OfwWYMAQBm_A"
    url = "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY"
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
    res = HTTPoison.get(url, [{"Authorization:", "Bearer #{socket.assigns.access_token}"}])

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

def handle_event("get-player", _params, socket) do
  url = "https://api.spotify.com/v1/me/player/devices"
  res = HTTPoison.get(url, [{"Authorization", "Bearer #{socket.assigns.access_token}"}])
  IO.inspect(res)
  case res do
    {:ok , %{status_code: 200, body: body}} ->
      IO.inspect(body)
      {:noreply, socket}

    {:ok, %{status_code: status_code, body: body}} ->
      Logger.info('#{status_code}')
      {:noreply, socket}

    {:error, error} ->
      Logger.info(error)
      {:noreply, socket}
  end

  {:noreply, socket}
end


def handle_event("start-timer", _params, socket) do
  timer_func()
  {:noreply, socket}
end

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  # Helper Functions



# Create a timer function for when the access token expires or is nil it will trigger a new fetch and assign the the correct values from the %Token{} into the socket
# This will then trigger another function to stream the song every 32 seconds and once that time is done trigger it to play again until the :access_token expires,
# once the access token expires it will trigger the timer function again to fetch a new token and then play the song again (recursively)

  def timer_func() do
    :erlang.start_timer(2000, self(), :fetch_token)
  end

  def handle_info({:timeout, _data, :fetch_token}, socket) do
    Logger.info('Timer Finished')
    fetch_token(socket)

    {:noreply, socket}
  end

  def fetch_token(socket) do
  url = "https://accounts.spotify.com/api/token"
  scopes = "streaming user-read-email user-read-private user-read-playback-state user-read-recently-played user-modify-playback-state"
  body = "grant_type=client_credentials&client_id=#{System.get_env("CLIENT_ID")}&client_secret=#{System.get_env("CLIENT_SECRET")}&scope=#{scopes}"
  headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

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





end
