# SpotifyBot

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  
# spotify-api
  * API docs: https://developer.spotify.com/documentation/web-api/reference/pause-a-users-playback
  * Status Codes: https://developer.spotify.com/documentation/web-api/concepts/api-calls

# Fetches Web Token
curl -X POST "https://accounts.spotify.com/api/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials&client_id=ae9e634bde02464480b62fa124143558&client_secret=b647f587af054503a8b96c5e1c890607"

# Fetches Willies spotify data artist/:id
 curl "https://api.spotify.com/v1/artists/3UR9ghLycQXaVDNJUNH3RY?si=aQ82WY_SS4OfwWYMAQBm_A" \
     -H "Authorization: Bearer  BQDtH-Ty-9hf8LtyWU5m0Hr93lp6vqM7i38YU6rTioqdgXwqMoPOYkQrxH0CIsFvET-xz-qG1wJQr8n7lymIxUEb9z2c0LFelkW_Yt1LANAW29MENqo"
