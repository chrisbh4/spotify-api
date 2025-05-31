defmodule SpotifyBotWeb.SpotifyLive do
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

          <!-- Instructions -->
          <div class="bg-[#1E293B] rounded-lg p-4 md:p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-4xl md:text-4xl font-semibold">How to Use</h2>
              <button
                phx-click="toggle-instructions"
                class="w-auto md:h-auto bg-[#383737] px-4 md:px-6 md:py-3 rounded-lg text-lg md:text-xl font-semibold transition transform border-black hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
              >
                <%= if @show_instructions, do: "Hide", else: "Open" %>
                <i class={"fas #{if @show_instructions, do: "fa-chevron-up", else: "fa-chevron-down"}"}></i>
              </button>
            </div>
            <div class={[
              "space-y-3 text-gray-300 #{if !@show_instructions, do: "hidden"}"
            ]}>
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-8 h-8 bg-[#383737] rounded-full flex items-center justify-center">1</div>
                <p class="sm:text-2xl md:text-2xl">Click the <span class="font-semibold text-white">Auth</span> button to authenticate with your Spotify account.</p>
              </div>
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-8 h-8 bg-[#383737] rounded-full flex items-center justify-center">2</div>
                <div class="sm:text-2xl md:text-2xl">
                  <p>Paste a Spotify song URL into the input field and click <span class="font-semibold text-white">Add Song to Bot</span>.</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-8 h-8 bg-[#383737] rounded-full flex items-center justify-center">3</div>
                <p class="sm:text-2xl md:text-2xl">Click <span class="font-semibold text-white">Start Bot</span> to begin automated streaming. The bot will continuously play the selected track.</p>
              </div>
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-8 h-8 bg-[#383737] rounded-full flex items-center justify-center">4</div>
                <p class="sm:text-2xl md:text-2xl">Monitor the status panel for stream count, current track, and token expiration. Click <span class="font-semibold text-white">Stop Bot</span> to end streaming.</p>
              </div>
            </div>
          </div>

          <!-- URL Input -->
          <div class="bg-[#1E293B] rounded-lg p-4 md:p-6">
            <form phx-submit="add-song-url" class="flex flex-col md:flex-row items-center gap-4">
              <input
                id="song-url"
                name="url"
                type="text"
                placeholder={"https://open.spotify.com/track/..."}
                class="w-full md:flex-1 bg-transparent sm:text-xl md:text-xl text-gray-200 placeholder-gray-500 focus:outline-none p-3 rounded-lg border border-gray-700"
              />
              <button
                type="submit"
                disabled={!@access_token}
                class="w-full md:w-auto bg-[#383737] h-20 md:h-auto sm:py-8 md:px-6 md:py-3 rounded-lg sm:text-xl md:text-xl font-semibold transition transform border-black hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
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
                class="bg-[#383737] h-20 px-6 py-4 rounded-lg sm:text-2xl md:text-3xl font-semibold transition transform border-black hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
              >
                <i class="fa-solid fa-key mr-2"></i> Auth
              </button>
              <button
                phx-click="start-timer"
                disabled={@track_uri == nil || @track_name == nil}
                class="bg-[#383737] h-20 px-6 py-4 rounded-lg sm:text-2xl md:text-3xl font-semibold transition transform border-black hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
              >
                <i class="fa-solid fa-play mr-2"></i> Start Bot
              </button>
              <button
                phx-click="kill-timer"
                disabled={@stream_status == "Idle" || @stream_status == "Loading..."}
                class="bg-[#383737] h-20 px-6 py-4 rounded-lg sm:text-2xl md:text-3xl font-semibold transition transform border-black hover:scale-105 hover:bg-[#444] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#383737]"
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
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 sm:text-xl md:text-3xl text-gray-300">
              <div class="space-y-3">
                <p><span class="text-gray-400">Auth Token:</span> <%= if @access_token, do: "✅", else: "❌" %></p>
                <p><span class="text-gray-400">Device ID:</span> <%= if @device_id !== nil, do: "Loaded ✅", else: "❌" %></p>
                <p><span class="text-gray-400">Song Data:</span> <%= if @stream_url != nil, do: " Loaded ✅", else: "❌" %></p>
              </div>
              <div class="space-y-3">
                <p><span class="text-gray-400">Current Track:</span><%= if @track_name !== nil, do: @track_name, else: "" %></p>
                <p><span class="text-gray-400">Stream Count:</span> <%= @stream_count %></p>
                <p><span class="text-gray-400">Token Expires in:</span> <%= if @expires_in !== nil, do: format_time(@expires_in), else: "00:00:00" %></p>
              </div>
            </div>
          </div>

          <!-- Device ID / Player -->
          <!-- This container required so that the SpotifyPlayer hook & event-handler can set the SpotifyPlayer device_ID into the socket state -->
          <div id="spotify-player" data={@access_token} phx-hook="SpotifyPlayer" class="hidden bg-[#1E293B] rounded-lg p-4 md:p-6">
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

    {:ok, assign(socket, countdown_time: 0, show_instructions: true)}
  end

  def handle_params(params, _uri, socket) do
    case params["code"] do
      nil ->
        Logger.info(":code is nil ❌")

        socket =
          assign(socket,
            code: nil,
            state: nil,
            access_token: nil,
            expires_in: nil,
            device_id: nil,
            track_uri: nil,
            track_name: nil,
            stream_count: 0,
            stream_url: nil,
            stream_status: "Idle",
            stream_time: nil
          )

        {:noreply, socket}

      _ ->
        Logger.info(":code in socket ✅")

        socket =
          assign(socket,
            code: params["code"],
            state: params["state"],
            access_token: nil,
            expires_in: nil,
            device_id: nil,
            track_uri: nil,
            track_name: nil,
            stream_count: 0,
            stream_url: nil,
            stream_status: "Idle",
            stream_time: nil
          )

        GenServer.cast(self(), :fetch_token)

        {:noreply, socket}
    end
  end

  def handle_cast(:fetch_token, socket) do
    {_, socket} = fetch_token(socket)
    {:noreply, socket}
  end

  def handle_event("toggle-instructions", _params, socket) do
    {:noreply, assign(socket, show_instructions: !socket.assigns.show_instructions)}
  end

  def handle_event("set-device-id", %{"device_id" => device_id}, socket) do
    Logger.info("Device Event triggered")
    IO.inspect(device_id, label: "Device ID")
    {:noreply, assign(socket, :device_id, device_id)}
  end

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
    with socket <- assign(socket, :stream_url, url),
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
    url = "https://accounts.spotify.com/authorize/?"
    redirect_uri = System.get_env("REDIRECT_URI") || "http://localhost:8080"
    scope = "user-read-email user-read-private streaming user-read-currently-playing"
    state = for _ <- 1..16, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

    query_params =
      [
        response_type: "code",
        client_id: System.get_env("CLIENT_ID"),
        scope: scope,
        redirect_uri: redirect_uri,
        state: state
      ]
      |> URI.encode_query()

    res = HTTPoison.get("#{url}#{query_params}")

    case res do
      {:ok, %{status_code: 200, body: _body}} ->
        Logger.info("Auth successful ✅")
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

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization",
       "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}
    ]

    res = HTTPoison.post(url, body, headers)

    case res do
      {:ok, %{status_code: 200, body: body}} ->
        Logger.info("Refreshed Token ✅")
        json_data = Jason.decode!(body)

        {:noreply,
         assign(socket,
           access_token: json_data["access_token"],
           expires_in: json_data["expires_in"]
         )}

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

    headers = [
      {"Authorization", "Bearer #{socket.assigns.access_token}"},
      {"Content-Type", "application/json"}
    ]

    body = ~c'{
      "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      "offset": {
          "position": 4
      },
      "position_ms": 0
    }'


    res = HTTPoison.put(url, body, headers)

    case res do
      {:ok, %{status_code: 204}} ->
        Logger.info("Playback started ✅")

        socket =
          socket
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
      {:ok, %{status_code: 200, body: body}} ->
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
    redirect_uri = System.get_env("REDIRECT_URI") || "http://localhost:8080"

    body =
      "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=#{redirect_uri}"

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization",
       "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}
    ]

    res = HTTPoison.post(url, body, headers)

    case res do
      {:ok, %{status_code: 200, body: body}} ->
        Logger.info("Access Token ✅")
        json_data = Jason.decode!(body)

        {:noreply,
         assign(socket,
           access_token: json_data["access_token"],
           expires_in: json_data["expires_in"],
           refresh_token: json_data["refresh_token"]
         )}

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

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization",
       "Basic #{Base.encode64("#{System.get_env("CLIENT_ID")}:#{System.get_env("CLIENT_SECRET")}")}"}
    ]

    res = HTTPoison.post(url, body, headers)

    case res do
      {:ok, %{status_code: 200, body: body}} ->
        Logger.info("Token Refreshed ✅")
        json_data = Jason.decode!(body)

        {:noreply,
         assign(socket,
           access_token: json_data["access_token"],
           expires_in: json_data["expires_in"],
           stream_status: "Idle"
         )}

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
  # * Error handling: figure out how to prevent Song Data logic from loading true
  def fetch_track_data(socket, url) do
    case url_translator(url) do
      nil ->
        Logger.error("Invalid Spotify URL format")
        {:noreply, assign(socket, stream_url: nil, track_name: nil)}

      api_url ->
        Logger.info("URL format succesful ✅ ")

        headers = [
          {"Authorization", "Bearer #{socket.assigns.access_token}"},
          {"Content-Type", "application/json"}
        ]

        case HTTPoison.get(api_url, headers) do
          {:ok, %{status_code: 200, body: body}} ->
            track_data = Jason.decode!(body)

            {:noreply,
             assign(socket, track_name: track_data["name"], track_uri: track_data["uri"])}

          {:error, error} ->
            Logger.error("Failed to fetch song data: #{inspect(error)}")
            {:noreply, socket}
        end
    end
  end

  def play_song(socket) do
    url = "https://api.spotify.com/v1/me/player/play?device_id=#{socket.assigns.device_id}"

    headers = [
      {"Authorization", "Bearer #{socket.assigns.access_token}"},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        uris: [socket.assigns.track_uri],
        position_ms: 0
      })

    res = HTTPoison.put(url, body, headers)

    case res do
      {:ok, %{status_code: 204}} ->
        Logger.info("Playback started ✅")

        socket =
          socket
          |> play_song_on_a_loop()
          |> assign(:stream_status, "Streaming")

        {:noreply, socket}

      {:ok, %{status_code: 202}} ->
        Logger.info("Play() not fully completed 🟠")

        socket =
          socket
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
      {:ok, %{status_code: 200}} ->
        Logger.info("Paused process ✅")
        {:noreply, socket}

      {:ok, %{status_code: 202}} ->
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



  def format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    remaining_seconds = rem(seconds, 60)

    "#{String.pad_leading(Integer.to_string(hours), 2, "0")}:#{String.pad_leading(Integer.to_string(minutes), 2, "0")}:#{String.pad_leading(Integer.to_string(remaining_seconds), 2, "0")}"
  end

  @doc """
  Translates a Spotify web URL to an API URL.
  Extracts the track ID and constructs the API endpoint URL.

  ## Examples
      iex> url_translator("https://open.spotify.com/track/3l4eYYvCzqd2Q37KkOBZGC?si=c8df893b37a94714")
      "https://api.spotify.com/v1/tracks/3l4eYYvCzqd2Q37KkOBZGC"

      iex> url_translator("https://open.spotify.com/track/3l4eYYvCzqd2Q37KkOBZGC")
      "https://api.spotify.com/v1/tracks/3l4eYYvCzqd2Q37KkOBZGC"
  """
  def url_translator(url) do
    # Extract track ID using regex
    case Regex.run(~r/track\/([a-zA-Z0-9]+)/, url) do
      [_, track_id] -> "https://api.spotify.com/v1/tracks/#{track_id}"
      nil -> nil
    end
  end
end
