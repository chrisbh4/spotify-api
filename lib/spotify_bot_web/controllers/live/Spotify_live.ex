defmodule SpotifyBotWeb.SpotifyLive do
  # alias ElixirLS.LanguageServer.Providers.FoldingRange.Token
  # alias ElixirSense.Log
  use Phoenix.LiveView
  require Logger

  # def render(assigns) do
  #   ~H"""
  #     <div class='flex justify-center w-full bg-red-500 '>
  #     <h1>Spotify API access point </h1>
  #     <button phx-click="auth-flow">Authentication Flow </button>
  #     <button phx-click="start-timer">Start Timer </button>
  #     <button phx-click="kill-timer">Stop Timer </button>
  #     <button phx-click="play-music">Play song </button>
  #     </div>
  #     <h1>Spotify Web Playback SDK Quick Start</h1>
  #     <script src="https://sdk.scdn.co/spotify-player.js"></script>
  #     <div id="spotify-player" data={@access_token} phx-hook="SpotifyPlayer">
  #       <script id="sdk-script"></script>
  #       <button id="togglePlay">Toggle Play</button>
  #       <button id="playSDK">Play</button>
  #     </div>
  #   """
  # end

def render(assigns) do
  ~H"""
    <head>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://sdk.scdn.co/spotify-player.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

  </head>
  <div class="bg-[#0F172A] text-white min-h-screen flex items-center justify-center text-4xl font-sans px-4">
    <%!-- <div class="w-full max-w-3xl md:w-[80%] space-y-6 text-2xl" > --%>
    <div class="w-full max-w-[25%] md:w-[80%] space-y-8 text-2xl mb-[30rem]" >

      <!-- Header -->
      <div class="text-center space-y-1">
        <%!-- <h1 class="text-5xl md:text-6xl font-semibold flex items-center justify-center gap-3"> --%>
        <h1 class="text-7xl font-semibold flex items-center justify-center gap-3">
          <%!-- <img src="https://upload.wikimedia.org/wikipedia/commons/1/19/Spotify_logo_without_text.svg" class="h-10 md:h-12" alt="Spotify" /> --%>
          <img src="https://upload.wikimedia.org/wikipedia/commons/1/19/Spotify_logo_without_text.svg" class="h-[5rem]" alt="Spotify" />
          Spotify Stream Bot
        </h1>
        <p class="text-4xl md:text-2xl text-gray-400">Automate your Spotify streaming with ease</p>
      </div>

      <!-- URL Input -->
      <div class="bg-[#1E293B] rounded-lg px-4 py-4 flex items-center gap-3">
        <input id="song-url" type="text" placeholder={@url} class="flex-1 bg-transparent text-4xl text-gray-200 placeholder-gray-500 focus:outline-none" />
        <button phx-click="load-song-url" phx-value-url={@url} class="bg-[#383737] px-[3.5rem] py-4 rounded-lg text-[1.8rem] font-semibold border-solid border-[#383737] transition w-full md:w-auto h-auto shadow-lg transform hover:scale-105 outline-[#383737]">Add Song to Bot</button>
        <%!-- <button phx-click="load-song-url" phx-value-url={@url} class="bg-[#334155] text-2xl px-4 py-2 rounded-md hover:bg-[#475569] transition">Add Song to Bot</button> --%>
        <%!--
          1. After the Url has been pasted and the "addded" button has been clicked change the Paste logo to a check mark with a word URL added
          2. If the user wants to add a different URL display a small <span> tag that will remove the URL and change the Icon back to add with no green check mark
         --%>
        <%!-- <button class="bg-[#334155] text-2xl px-4 py-2 rounded-md hover:bg-[#475569] transition">📋 Paste</button> --%>
        <%!-- <button class="bg-[#334155] text-2xl px-4 py-2 rounded-md hover:bg-[#475569] transition">Load the URL into the bot</button> --%>
        <%!-- <button class="bg-[#334155] text-2xl px-4 py-2 rounded-md hover:bg-[#475569] transition">Fetch Song to stream</button> --%>
      </div>

      <!-- Bot Controls -->
      <div class="bg-[#1E293B] rounded-lg px-6 py-4 flex flex-col md:flex-row justify-between gap-3">
        <button phx-click="auth-flow" class="bg-[#383737] px-[5.5rem] py-4 rounded-lg text-[1.8rem] font-semibold border-solid border-[#383737] transition w-full md:w-auto h-auto shadow-lg transform hover:scale-105 outline-[#383737]"><i class="fa-solid fa-key mr-2"></i> Auth</button>
        <button phx-click="start-timer" class="bg-[#383737] px-[5.5rem] py-4 rounded-lg text-[1.8rem] font-semibold border-solid border-[#383737] transition w-full md:w-auto h-auto shadow-lg transform hover:scale-105"><i class="fa-solid fa-play mr-2"></i> Start Bot</button>
        <button phx-click="kill-timer" class="bg-[#383737] px-[5.5rem] py-4 rounded-lg text-[1.8rem] font-semibold border-solid border-[#383737] transition w-full md:w-auto h-auto shadow-lg transform hover:scale-105"> <i class="fas fa-stop mr-2"></i> Stop Bot</button>

        <%!-- <button phx-click="auth-flow" class="bg-gradient-to-r from-blue-500 to-indigo-500 px-8 py-4 rounded-lg text-[2.8rem] font-semibold hover:from-blue-600 hover:to-indigo-600 transition w-full md:w-auto h-auto shadow-lg transform hover:scale-105">🔑 Auth</button> --%>
        <%!-- <button phx-click="start-timer" class="bg-gradient-to-r from-green-400 to-green-600 px-8 py-4 rounded-lg text-[2.8rem] font-semibold hover:from-green-500 hover:to-green-700 transition w-full md:w-auto h-auto shadow-lg transform hover:scale-105">▶ Start Bot</button> --%>
        <%!-- <button phx-click="kill-timer" class="bg-gradient-to-r from-red-400 to-red-600 px-8 py-4 rounded-lg text-[2.8rem] font-semibold hover:from-red-500 hover:to-red-700 transition w-full md:w-auto h-auto shadow-lg transform hover:scale-105">⏹ Stop Bot</button> --%>
      </div>

      <!-- Status Panel -->
      <%!-- <div class="bg-[#1E293B] rounded-lg px-4 py-4"> --%>
      <div class="bg-[#1E293B] rounded-lg px-8 py-8">
        <div class="flex justify-between items-center mb-3">
          <span class="font-medium text-4xl">Status</span>
          <span class="text-3xl bg-[#334155] px-8 py-2 rounded-full">Idle</span>
        </div>
        <div class="text-3xl text-gray-300 space-y-1">
          <%!-- If Auth is 200 then display a green check mark else display a red x ❌ --%>
          <p><span class="text-gray-400">Auth:</span> ❌</p>
          <p><span class="text-gray-400">Current Track:</span> Not playing</p>
          <p><span class="text-gray-400">Stream Count:</span> <%= @stream_count %></p>
          <p><span class="text-gray-400">Running Time:</span> 00:00:00</p>
        </div>
      </div>
    </div>
  </div>
  """
end



  def mount(_params, _, socket) do
    {:ok, socket}
  end

 def handle_params(params, _uri, socket) do
    case params["code"] do
      nil ->
        Logger.info(":code is nil ❌")
        socket = assign(socket, code: nil, state: nil, access_token: nil, stream_count: 0, url: "https://api.spotify.com/v1/artists/...")
        {:noreply, socket}

      _ ->
        Logger.info(":code in socket ✅")
        socket = assign(socket, code: params["code"], state: params["state"], access_token: nil, stream_count: 0, url: "https://api.spotify.com/v1/artists/...")

        GenServer.cast(self(), :fetch_token)

        {:noreply, socket}
    end
  end

  def handle_cast(:fetch_token, socket) do
    {_, socket} = fetch_token(socket)
    {:noreply, socket}
  end

  def handle_event("set-device-id", %{"device_id" => device_id}, socket) do
    IO.inspect(device_id, label: "Device ID")
    {:noreply, assign(socket, :device_id, device_id)}
  end

  # Disable The stream but test if the count stays after the loop happens again
  def handle_event("start-timer", _params, socket) do
    start_timer()
    {:noreply, socket}
  end

  def handle_event("kill-timer", _params, socket) do
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

  def handle_event("load-song-url", %{"url" => url}, socket) do
    socket = assign(socket, :url, url)
    Logger.info("URL: #{url}")
    {:noreply, socket}
  end

  # Authorization Code Flow: Single Grant token only this is why it is refreshing everytime
  def handle_event("auth-flow", _params, socket) do
    url = "https://accounts.spotify.com/authorize?"
    redirect_uri = "https://spotify-api.fly.dev"
    # redirect_uri = "http://localhost:8080"
    scope = "user-read-email user-read-private user-read-playback-state user-read-recently-played user-modify-playback-state streaming user-read-currently-playing"
    # state = for _ <- 1..16, into: "", do: <<Enum.random('0123456789abcdef')>>
    state = for _ <- 1..16, into: "", do: <<Enum.random("0123456789abcdef")>>

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
    # body = '{
    #   "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
    #   "offset": {
    #       "position": 4
    #   },
    #   "position_ms": 0
    # }'
    body = Jason.encode!(%{
      context_uri: "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      offset: %{position: 4},
      position_ms: 0
    })

    res = HTTPoison.put(url, body, headers)
    case res do
      {:ok , %{status_code: 204}} ->
        Logger.info("Playback started ✅")
        socket = socket.assign(:stream_count, socket.assigns.stream_count + 1)
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
    pause_song(socket)
    Logger.info("Timer stopped")
  end

  def play_song_on_a_loop(socket) do
    # timer_ref = :erlang.start_timer(5000, self(), :loop_song)
    timer_ref = :erlang.start_timer(33000, self(), :loop_song)
    # socket = socket.assign(:stream_count, socket.assigns.stream_count + 1)
    assign(socket, timer_ref: timer_ref)
  end


  def fetch_token(socket) do
    url = "https://accounts.spotify.com/api/token"
    body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=https://spotify-api.fly.dev"
    # body = "grant_type=authorization_code&code=#{socket.assigns.code}&redirect_uri=http://localhost:8080"
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


  def play_song(socket) do
    url = "https://api.spotify.com/v1/me/player/play?device_id=#{socket.assigns.device_id}"
    headers = [{"Authorization", "Bearer #{socket.assigns.access_token}"}, {"Content-Type", "application/json"}]
    # body = '{
    #   "context_uri": "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
    #   "offset": {
    #       "position": 4
    #   },
    #   "position_ms": 0
    # }'
    body = Jason.encode!(%{
      context_uri: "spotify:album:5ht7ItJgpBH7W6vJ5BqpPr",
      offset: %{position: 4},
      position_ms: 0
    })

    res = HTTPoison.put(url, body, headers)
    case res do
      {:ok , %{status_code: 204}} ->
        Logger.info("Playback started ✅")
        socket = play_song_on_a_loop(socket)
        # socket = assign(socket, stream_count: socket.assigns.stream_count + 1)
        # Logger.info("Stream Count: #{socket.assigns.stream_count}")
        {:noreply, socket}

        {:ok , %{status_code: 202}} ->
        Logger.info("Play() not fully completed 🟠")
        socket = play_song_on_a_loop(socket)
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
      {:ok , %{status_code: 204}} ->
        Logger.info("Paused process ✅")
        {:noreply, socket}

        {:ok , %{status_code: 202}} ->
        Logger.info("Paused process with Issues ⏸️")
        {:noreply, socket}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.info("Paused failed ❌")
        Logger.info(status_code: status_code)
        IO.inspect(body)
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

end
