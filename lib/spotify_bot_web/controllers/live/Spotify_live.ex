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
    IO.inspect("button click")
    {:noreply, socket}
  end
end
