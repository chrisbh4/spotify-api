defmodule SpotifyBotWeb.SpotifyLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
      <h1>Spotify API access point </h1>
      <button phx-click="btn-click">Access API </button>
    """
  end


  def mount(_params, _ , socket) do
    {:ok, socket}
  end


  def handle_event("btn-click", _, socket) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end

    {:noreply, socket}
  end

  # def handle_event("btn-click", _, socket) do
  #   IO.inspect("button click")
  #   {:noreply, socket}
  # end
end
