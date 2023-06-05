defmodule SpotifyBotWeb.ThermostatLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    Current temperature: <%= @temperature %>
    <button phx-click="inc_temperature">+</button>
    <button phx-click="dec_temperature">-</button>
    """
  end

  def mount(_params, _ , socket) do
    # temperature = Thermostat.get_user_reading(user_id)
    {:ok, assign(socket, :temperature, 50)}
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  def handle_event("dec_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 - 1))}
  end
end
