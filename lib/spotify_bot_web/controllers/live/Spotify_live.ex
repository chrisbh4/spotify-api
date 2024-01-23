defmodule SpotifyBotWeb.SpotifyLive do
  # alias ElixirLS.LanguageServer.Providers.FoldingRange.Token
  # alias ElixirSense.Log
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    ~H"""
      <div class='flex justify-center w-full bg-red-500 '>
      <h1>Spotify API access point </h1>
      <button phx-click="auth-flow">Authentication Flow </button>
      <button phx-click="start-timer">Start Timer </button>
      <button phx-click="kill-timer">Stop Timer </button>
    <%!--
      <button phx-click="fetch-token">Generate Token </button>
      <button phx-click="play-music">Play Music </button>
      <button phx-click="pkce-auth">PKCE Auth Flow </button>
      <button phx-click="refresh-token">Refresh Token </button>
      <button phx-click="get-devices">Get Device </button>
    --%>
    <%!--
      <button phx-click="fetch-artist">Artist data </button>
      <button phx-click="fetch-top-tracks">Top Tracks </button>
      <button phx-click="fetch-playlist"> Demo Playlist</button>
      <button phx-click="get-currently-playing">Currently Playing </button>
      <button phx-click="fetch-queue">Fetch Queue </button>
      <button phx-click="play-song">Play music </button>
    --%>
      </div>
    """
  end

  def mount(_params, _, socket) do
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    case params["code"] do
      nil ->
        # Logger.info("Auth :code is nil ❌")
        socket = assign(socket, code: nil, state: nil)
        {:noreply, socket}

      _ ->
        Logger.info("Auth :code in socket ✅")
        socket = assign(socket, code: params["code"], state: params["state"])
        {:noreply, socket}
    end
  end

  def handle_event("start-timer", _params, socket) do
    start_timer()
    {:noreply, socket}
  end

  def handle_event("kill-timer", _params, socket) do
    kill_timer_loop(socket)
    {:noreply, socket}
  end

  # Authorization Code Flow: Single Grant token only this is why it is refreshing everytime
  def handle_event("auth-flow", _params, socket) do
    url = "https://accounts.spotify.com/authorize?"
    redirect_uri = "http://localhost:4000"
    scope = "user-read-email user-read-private user-read-playback-state user-read-recently-played user-modify-playback-state streaming user-read-currently-playing"
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

    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Auth successful ✅")
        json_data = Jason.decode!(body)
        IO.inspect(json_data)
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: _body, request_url: request_url}} ->
        Logger.info(status_code: status_code)
        {:noreply, redirect(socket, external: request_url)}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
      end
  end

  # Authorization Code Flow fetch token // Single Grant token only this is why it is refreshing everytime
  def handle_event("fetch-token", _params, socket) do
    url = "https://accounts.spotify.com/api/token"
    body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=http://localhost:4000"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]

    res = HTTPoison.post(url, body, headers)
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Auth Token with Code fetched ✅")
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
    url = "https://accounts.spotify.com/api/token"
    body = "grant_type=refresh_token&refresh_token=#{socket.assigns.refresh_token}"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]

    res = HTTPoison.post(url, body, headers)
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

  def handle_event("play-music", _params, socket) do
    # Macbook App
    url = "https://api.spotify.com/v1/me/player/play?device_id=9f178b17255f6334556f45148bc1fa3a564ee14e"
    # Chrome Web Player
    # url = "https://api.spotify.com/v1/me/player/play?device_id=438a73099346ce1736084c4ba4bc7f01e00a940f"
    headers = [{"Authorization", "Bearer #{socket.assigns.access_token}"}, {"Content-Type", "application/json"}]
    # offset: is the position of the song in the album in array format starting at 0
    body = '{
      "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      "offset": {
          "position": 4
      },
      "position_ms": 0
    }'

    res = HTTPoison.put(url, body, headers)
    case res do
      {:ok , %{status_code: 204}} ->
        Logger.info("Playback started ✅")
        {:noreply, socket}

      {:ok, %{status_code: 401}} ->
        Logger.info("Expired Token ❌")
        Logger.info(status_code: 401)
        refresh_token(socket)
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info("Playback failed ❌")
        Logger.info(status_code: status_code)
        IO.inspect(body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  def handle_event("get-devices", _params, socket) do
    url = "https://api.spotify.com/v1/me/player/devices"
    res = HTTPoison.get(url, [{"Authorization", "Bearer #{socket.assigns.access_token}"}])
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Devices fetched ✅")
        IO.inspect(Jason.decode!(body))
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info("Devices fetch failed ❌")
        Logger.info(status_code: status_code)
        IO.inspect(body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  def handle_event("get-currently-playing", _params, socket) do
    url = "https://api.spotify.com/v1/me/player/currently-playing"
    res = HTTPoison.get(url, [{"Authorization", "Bearer #{socket.assigns.access_token}"}])
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        IO.inspect(body)
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info('#{status_code}')
        IO.inspect(body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  def handle_event("fetch-queue", _params, socket) do
    url = "https://api.spotify.com/v1/me/player/queue"
    res = HTTPoison.get(url, [{"Authorization", "Bearer #{socket.assigns.access_token}"}])
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        IO.inspect(body)
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info('#{status_code}')
        IO.inspect(body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  def handle_info({:timeout, _data, :fetch_token}, socket) do
    token = fetch_token(socket)
    case token do
      {:noreply, socket} ->
        Logger.info("Token & Timer ✅")
        play_song_on_a_loop(socket)
        {:noreply, socket}
    end
  end

  def handle_info({:timeout, _data, :loop_song}, socket) do
    play_song(socket)
  end


  # ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  # Helper Functions
  # Create a timer function for when the access token expires or is nil it will trigger a new fetch and assign the the correct values from the %Token{} into the socket
  # This will then trigger another function to stream the song every 32 seconds and once that time is done trigger it to play again until the :access_token expires,
  # once the access token expires it will trigger the timer function again to fetch a new token and then play the song again (recursively)

  # Fetches the token on a timer
  def start_timer() do
    :erlang.start_timer(2000, self(), :fetch_token)
  end

  def kill_timer_loop(socket) do
    :erlang.cancel_timer(socket.assigns.timer_ref)
    Logger.info("Timer stopped")
  end

  def play_song_on_a_loop(socket) do
    timer_ref = :erlang.start_timer(3000, self(), :loop_song)
    assign(socket, timer_ref: timer_ref)
  end

  def fetch_token(socket) do
    url = "https://accounts.spotify.com/api/token"
    body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=http://localhost:4000"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]

    res = HTTPoison.post(url, body, headers)
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Auth Token with Code fetched ✅")
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

  def play_song(socket) do
    url = "https://api.spotify.com/v1/me/player/play?device_id=9f178b17255f6334556f45148bc1fa3a564ee14e"
    headers = [{"Authorization", "Bearer #{socket.assigns.access_token}"}, {"Content-Type", "application/json"}]
    body = '{
      "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      "offset": {
          "position": 4
      },
      "position_ms": 0
    }'

    res = HTTPoison.put(url, body, headers)
    case res do
      {:ok , %{status_code: 204}} ->
        Logger.info("Playback started ✅")
        socket = play_song_on_a_loop(socket)
        {:noreply, socket}

      {:ok, %{status_code: 401}} ->
        Logger.info("Expired Token ❌")
        Logger.info(status_code: 401)
        refresh_token(socket)
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info("Playback failed ❌")
        Logger.info(status_code: status_code)
        IO.inspect(body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  def refresh_token(socket) do
    url = "https://accounts.spotify.com/api/token"
    body = "grant_type=refresh_token&refresh_token=#{socket.assigns.refresh_token}"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]

    res = HTTPoison.post(url, body, headers)
    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Token Refreshed ✅")
        json_data = Jason.decode!(body)
        play_song_on_a_loop(socket)
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

  @charset "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  def generate_random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> :binary.bin_to_list()
    |> Enum.map(&char_for(&1))
    |> Enum.join()
  end

  defp char_for(byte) do
    String.at(@charset, rem(byte, String.length(@charset)))
  end

  def generate_hash_and_base64(code_verifier) do
    :crypto.hash(:sha256, code_verifier)
    |> Base.url_encode64()
    |> String.trim_trailing("=")
  end

end
