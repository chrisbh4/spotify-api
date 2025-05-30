defmodule SpotifyBotWeb.SpotifyLive do
  # alias ElixirLS.LanguageServer.Providers.FoldingRange.Token
  # alias ElixirSense.Log
  use Phoenix.LiveView
  require Logger

def render(assigns) do
  ~H"""
    <head>
      <script src="https://cdn.tailwindcss.com"></script>
      <script src="https://sdk.scdn.co/spotify-player.js"></script>
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    </head>
    <div class="bg-[#0F172A] text-white min-h-screen p-4 md:p-8">
      <div class="max-w-7xl mx-auto space-y-6">
        <!-- Header -->
        <div class="text-center space-y-4">
          <h1 class="text-4xl md:text-7xl font-semibold flex items-center justify-center gap-3">
            <img src="https://upload.wikimedia.org/wikipedia/commons/1/19/Spotify_logo_without_text.svg" class="h-10 md:h-16" alt="Spotify" />
            <span class="hidden md:inline">Spotify Stream Bot</span>
            <span class="md:hidden">Stream Bot</span>
          </h1>
          <p class="text-lg md:text-2xl text-gray-400">Automate your Spotify streaming with ease</p>
        </div>

        <!-- URL Input -->
        <div class="bg-[#1E293B] rounded-lg p-4 md:p-6">
          <form phx-submit="add-song-url" class="flex flex-col md:flex-row items-center gap-4">
            <input
              id="song-url"
              name="url"
              type="text"
              placeholder={@url}
              class="w-full md:flex-1 bg-transparent sm:text-xl md:text-xl text-gray-200 placeholder-gray-500 focus:outline-none p-3 rounded-lg border border-gray-700"
            />
            <button
              type="submit"
              class="w-full md:w-auto bg-[#383737] h-20 md:h-auto sm:py-8 md:px-6 md:py-3 rounded-lg sm:text-xl md:text-xl font-semibold transition transform hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
            >
              Add Song to Bot
            </button>
          </form>
        </div>

        <!-- Bot Controls -->
        <div class="bg-[#1E293B] rounded-lg p-4 md:p-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button
              phx-click="auth-flow"
              class="bg-[#383737] h-20 px-6 py-4 rounded-lg sm:text-2xl md:text-3xl font-semibold transition transform hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
            >
              <i class="fa-solid fa-key mr-2"></i> Auth
            </button>
            <button
              phx-click="start-timer"
              class="bg-[#383737] h-20 px-6 py-4 rounded-lg sm:text-2xl md:text-3xl font-semibold transition transform hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
            >
              <i class="fa-solid fa-play mr-2"></i> Start Bot
            </button>
            <button
              phx-click="kill-timer"
              class="bg-[#383737] h-20 px-6 py-4 rounded-lg sm:text-2xl md:text-3xl font-semibold transition transform hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
            >
              <i class="fas fa-stop mr-2"></i> Stop Bot
            </button>
          </div>
        </div>

        <!-- Status Panel -->
        <div class="bg-[#1E293B] rounded-lg p-4 md:p-8">
          <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
            <span class="text-2xl md:text-3xl font-medium">Status</span>
            <span class={
              "text-2xl md:text-2xl px-4 md:px-8 py-2 rounded-full font-bold #{
                cond do
                  @stream_status == "Streaming" -> "bg-green-500"
                  @stream_status == "Paused" -> "bg-red-400"
                  true -> "bg-[#334155]"
                end
              }"
            }><%= @stream_status %></span>
          </div>
          <%!-- <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-base md:text-3xl text-gray-300"> --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 sm:text-xl md:text-3xl text-gray-300">
            <div class="space-y-3">
              <p><span class="text-gray-400">Auth Token:</span> <%= if @access_token, do: "✅", else: "❌" %></p>
              <p><span class="text-gray-400">Device ID:</span> <%= if @device_id !== nil, do: "Loaded ✅", else: "❌" %></p>
              <p><span class="text-gray-400">Song Data:</span> <%= if @url != "https://api.spotify.com/v1/artists/...", do: " Loaded ✅", else: "❌" %></p>
            </div>
            <div class="space-y-3">
              <p><span class="text-gray-400">Current Track:</span><%= if @track_name !== nil, do: @track_name, else: "Not Playing" %></p>
              <p><span class="text-gray-400">Stream Count:</span> <%= @stream_count %></p>
              <p><span class="text-gray-400">Token Expires in:</span> <%= if @expires_in !== nil, do: format_time(@expires_in), else: "00:00:00" %></p>
            </div>
          </div>
        </div>

        <!-- Player -->
        <div id="spotify-player" data={@access_token} phx-hook="SpotifyPlayer" class="bg-[#1E293B] rounded-lg p-4 md:p-6">
          <div class="flex flex-col md:flex-row gap-4 justify-center items-center">
            <button
              id="togglePlay"
              class="w-full md:w-auto bg-[#383737] px-6 py-3 rounded-lg text-lg md:text-xl font-semibold transition transform hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
            >
              Toggle Play
            </button>
            <button
              id="playSDK"
              class="w-full md:w-auto bg-[#383737] px-6 py-3 rounded-lg text-lg md:text-xl font-semibold transition transform hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
            >
              Play
            </button>
          </div>
        </div>
      </div>
    </div>
  """
end

# * OLD UI for spotify Bot
# def render(assigns) do
#     ~H"""
#       <div class='flex justify-center w-full bg-red-500 '>
#       <h1>Spotify API access point </h1>
#       <button phx-click="auth-flow">Authentication Flow </button>
#       <button phx-click="start-timer">Start Timer </button>
#       <button phx-click="kill-timer">Stop Timer </button>
#       <button phx-click="play-music">Play song </button>
#       </div>
#       <h1>Spotify Web Playback SDK Quick Start</h1>
#       <script src="https://sdk.scdn.co/spotify-player.js"></script>
#       <div id="spotify-player" data={@access_token} phx-hook="SpotifyPlayer">
#         <script id="sdk-script"></script>
#         <button id="togglePlay">Toggle Play</button>
#         <button id="playSDK">Play</button>
#       </div>
#     """
#   end


  # Mount is called when the LiveView is first rendered
  # Here we set up:
  # 1. A timer that sends a :tick message every second when the socket is connected
  # 2. This timer is used to update the token expiration countdown
  # 3. The countdown starts at 0 and will be updated when we receive the token
  # 4. connected?(socket) ensures we only start the timer when we have a live connection
  #    to avoid running timers in disconnected states
  def mount(_params, _, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end
    {:ok, assign(socket, countdown_time: 0)}
  end

 def handle_params(params, _uri, socket) do
    case params["code"] do
      nil ->
        Logger.info(":code is nil ❌")
        # Change URL socket state to stream_url
        socket = assign(socket, code: nil, state: nil, access_token: nil, expires_in: nil, device_id: nil, track_name: nil, stream_count: 0, url: "https://api.spotify.com/v1/artists/...", stream_status: "Idle", stream_time: nil)
        {:noreply, socket}

      _ ->
        Logger.info(":code in socket ✅")
        # Is assigning URL: to the default string fucking it up?
        socket = assign(socket, code: params["code"], state: params["state"], access_token: nil, expires_in: nil, device_id: nil, track_name: nil, stream_count: 0, url: "https://api.spotify.com/v1/artists/...", stream_status: "Idle", stream_time: nil)

        GenServer.cast(self(), :fetch_token)

        {:noreply, socket}
    end
  end

  def handle_cast(:fetch_token, socket) do
    {_, socket} = fetch_token(socket)
    {:noreply, socket}
  end

  def handle_event("set-device-id", %{"device_id" => device_id}, socket) do
    Logger.info("Device Event triggered")
    IO.inspect(device_id, label: "Device ID")
    {:noreply, assign(socket, :device_id, device_id)}
  end

  # Disable The stream but test if the count stays after the loop happens again
  def handle_event("start-timer", _params, socket) do
    socket = assign(socket, :stream_status, "Loading...")
    start_timer()
    {:noreply, socket}
  end

  def handle_event("kill-timer", _params, socket) do
    socket = assign(socket, :stream_status, "Paused")
    kill_timer_loop(socket)
    {:noreply, socket}
  end

  def handle_event("start-bot", _params, socket) do
    start_timer()
    {:noreply, socket}
  end

  def handle_event("stop-bot", _params, socket) do
    kill_timer_loop(socket)
    {:noreply, socket}
  end

  @doc """
  Handles the add-song-url event triggered by the URL input form.
  1. Assigns the URL to socket state
  2. Fetches song metadata from Spotify API
  3. Updates LiveView with track name
  """
  def handle_event("add-song-url", %{"url" => url}, socket) do
    with socket <- assign(socket, :url, url),
         {:noreply, updated_socket} <- fetch_track_data(socket, url) do
      {:noreply, updated_socket}
    end
  end

  def handle_event("update-url", %{"value" => url}, socket) do
    # Process the URL (e.g., validate or store it)
    Logger.info("Key Up: #{url}")
    {:noreply, assign(socket, :url, url)}
  end

  # Authorization Code Flow: Single Grant token only this is why it is refreshing everytime
  def handle_event("auth-flow", _params, socket) do
    # * Figure out the diffeence between the 2 url variables
    # url = "https://accounts.spotify.com/authorize?"
    url = "https://accounts.spotify.com/authorize/?"
    redirect_uri = "https://spotify-api.fly.dev"
    # localhost_redirect_uri = "http://localhost:8080"
    # scope = "user-read-email user-read-private user-read-playback-state user-read-recently-played user-modify-playback-state streaming user-read-currently-playing"
    scope = "user-read-email user-read-private streaming user-read-currently-playing"
    state = for _ <- 1..16, into: "", do: <<Enum.random('0123456789abcdef')>>
    # state = for _ <- 1..16, into: "", do: <<Enum.random("0123456789abcdef")>>

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
      {:ok , %{status_code: 200, body: _body}} ->
        Logger.info("Auth successful ✅")
        # json_data = Jason.decode!(body)
        # IO.inspect(json_data)
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: _body, request_url: request_url}} ->
        Logger.info(status_code: status_code)
        {:noreply, redirect(socket, external: request_url)}

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

  def handle_event("play-music", _params, socket) do
    url = "https://api.spotify.com/v1/me/player/play?device_id=#{socket.assigns.device_id}"
    headers = [{"Authorization", "Bearer #{socket.assigns.access_token}"}, {"Content-Type", "application/json"}]
    # offset: is the position of the song in the album in array format starting at 0
    body = '{
      "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      "offset": {
          "position": 4
      },
      "position_ms": 0
    }'
    # body = Jason.encode!(%{
    #   context_uri: "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
    #   offset: %{position: 4},
    #   position_ms: 0
    # })

    res = HTTPoison.put(url, body, headers)
    case res do
      {:ok , %{status_code: 204}} ->
        Logger.info("Playback started ✅")
        socket = socket
        |> assign(:stream_status, "Streaming")
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
        Logger.info("#{status_code}")
        IO.inspect(body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
    end
  end

  # def handle_info({:timeout, _data, :fetch_token}, socket) do
  #   token = fetch_token(socket)
  #   case token do
  #     {:noreply, socket} ->
  #       Logger.info("Token & Timer ✅")
  #       play_song_on_a_loop(socket)
  #       {:noreply, socket}
  #   end
  # end

  def handle_info({:timeout, _data, :fetch_token}, socket) do
        Logger.info("Token & Timer ✅")
        play_song_on_a_loop(socket)
        {:noreply, socket}
  end

  def handle_info({:timeout, _data, :loop_song}, socket) do
    socket = assign(socket, stream_count: socket.assigns.stream_count + 1)
    play_song(socket)
  end

  def handle_info(:tick, socket) do
    if socket.assigns.expires_in && socket.assigns.expires_in > 0 do
      {:noreply, assign(socket, expires_in: socket.assigns.expires_in - 1)}
    else
      {:noreply, socket}
    end
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
    pause_song(socket)
    Logger.info("Bot timer stopped")
  end

  def play_song_on_a_loop(socket) do
    timer_ref = :erlang.start_timer(5000, self(), :loop_song)
    # timer_ref = :erlang.start_timer(33000, self(), :loop_song)
    assign(socket, timer_ref: timer_ref)
  end


  def fetch_token(socket) do
    url = "https://accounts.spotify.com/api/token"
    body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=https://spotify-api.fly.dev"
    # localhost_body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=http://localhost:8080"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]
    res = HTTPoison.post(url, body, headers)

    case res do
      {:ok , %{status_code: 200, body: body}} ->
        Logger.info("Access Token ✅")
        json_data = Jason.decode!(body)
        {:noreply, assign(socket, access_token: json_data["access_token"], expires_in: json_data["expires_in"], refresh_token: json_data["refresh_token"])}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info(status_code: status_code)
        Logger.info("❌Bad Fetch token❌")
        Logger.info(body: body)
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
        {:noreply, assign(socket, access_token: json_data["access_token"], expires_in: json_data["expires_in"], stream_status: "Idle")}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info(status_code: status_code)
        Logger.info(body: body)
        {:noreply, socket}

      {:error, error} ->
        Logger.info(error)
        {:noreply, socket}
      end
  end

  @doc """
  Fetches song metadata from Spotify API using the track ID.
  Returns track name and updates LiveView state.

  Example response:
  ```
  {
    "name": "Track Name",
    "artists": [...],
    "album": {...}
  }
  ```
  """
  def fetch_track_data(socket, _url) do
    url = "https://api.spotify.com/v1/tracks/11dFghVXANMlKmJXsNCbNl"
    headers = [
      {"Authorization", "Bearer #{socket.assigns.access_token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        track_data = Jason.decode!(body)
        {:noreply, assign(socket, track_name: track_data["name"])}

      {:error, error} ->
        Logger.error("Failed to fetch song data: #{inspect(error)}")
        {:noreply, socket}
    end
  end

  def play_song(socket) do
    url = "https://api.spotify.com/v1/me/player/play?device_id=#{socket.assigns.device_id}"
    headers = [{"Authorization", "Bearer #{socket.assigns.access_token}"}, {"Content-Type", "application/json"}]
    # "context_uri": socket.assigns.url,
    body = '{
      "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      "offset": {
          "position": 4
      },
      "position_ms": 0
    }'
    # body = Jason.encode!(%{
    #   context_uri: "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
    #   # context_uri: socket.assigns.url,
    #   offset: %{position: 4},
    #   position_ms: 0
    # })

    # * I'll have to fetch the data first to get the Track info and then plug it into the URL which will help for USer input when they have a song data to load up

    # Figure out how to get the current stream time into the socket state
    res = HTTPoison.put(url, body, headers)
    case res do
      {:ok , %{status_code: 204}} ->
        Logger.info("Playback started ✅")
        socket = socket
                |> play_song_on_a_loop()
                |> assign(:stream_status, "Streaming")
        {:noreply, socket}

      {:ok , %{status_code: 202}} ->
        Logger.info("Play() not fully completed 🟠")
        socket = socket
                |> play_song_on_a_loop()
                |> assign(:stream_status, "Streaming")
        {:noreply, socket}

      {:ok, %{status_code: 401}} ->
        Logger.info("Expired Token ❌")
        Logger.info(status_code: 401)
        {_, socket} = refresh_token(socket)
        play_song_on_a_loop(socket)
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

  def pause_song(socket) do
    url = "https://api.spotify.com/v1/me/player/pause"
    headers = [{"Authorization", "Bearer #{socket.assigns.access_token}"}]
    res = HTTPoison.put(url, "", headers)
    case res do
      {:ok , %{status_code: 200}} ->
        Logger.info("Paused process ✅")
      {:noreply, socket}

      {:ok , %{status_code: 202}} ->
        Logger.info("Paused process with Issues 🟠")
      {:noreply, socket}

      {:ok, %{status_code: status_code, body: _body}} ->
        Logger.info("Pause request error ❌")
        Logger.info(status_code: status_code)
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


   # Authorization Code Flow fetch token // Single Grant token only this is why it is refreshing everytime
  #  def handle_event("fetch-token", _params, socket) do
  #   url = "https://accounts.spotify.com/api/token"
  #   # body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=http://localhost:4000"
  #   body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=https://spotify-api.fly.dev"
  #   headers = [{"Content-Type", "application/x-www-form-urlencoded"}, {"Authorization", "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}]

  #   res = HTTPoison.post(url, body, headers)
  #   case res do
  #     {:ok , %{status_code: 200, body: body}} ->
  #       Logger.info("Auth Token with Code fetched ✅")
  #       json_data = Jason.decode!(body)
  #       {:noreply, assign(socket, access_token: json_data["access_token"], expires_in: json_data["expires_in"], refresh_token: json_data["refresh_token"])}

  #     {:ok, %{status_code: status_code, body: body}} ->
  #       Logger.info(status_code: status_code)
  #       Logger.info(body: body)
  #       {:noreply, socket}

  #     {:error, error} ->
  #       Logger.info(error)
  #       {:noreply, socket}
  #     end
  # end

  def format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    remaining_seconds = rem(seconds, 60)

    "#{String.pad_leading(Integer.to_string(hours), 2, "0")}:#{String.pad_leading(Integer.to_string(minutes), 2, "0")}:#{String.pad_leading(Integer.to_string(remaining_seconds), 2, "0")}"
  end

end
