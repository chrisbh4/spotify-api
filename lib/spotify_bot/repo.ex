defmodule SpotifyBot.Repo do
  use Ecto.Repo,
    otp_app: :spotify_bot,
    adapter: Ecto.Adapters.Postgres
end
