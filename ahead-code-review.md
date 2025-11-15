# Spotify Stream Bot - Code Review & SaaS Improvements

**Date**: 2025-11-09
**Project**: Spotify Stream Bot (Elixir/Phoenix)
**Current State**: Proof-of-Concept → SaaS-Level Free Tier

---

## Table of Contents

1. [Comprehensive Codebase Analysis](#comprehensive-codebase-analysis)
2. [Current State Assessment](#current-state-assessment)
3. [SaaS-Level Improvements](#saas-level-improvements)
4. [Feature Summaries](#feature-summaries)
5. [Priority Matrix](#priority-matrix)
6. [Recommended Next Steps](#recommended-next-steps)

---

## Comprehensive Codebase Analysis

### 1. Technology Stack

**Language & Framework:**
- **Language**: Elixir 1.12+
- **Web Framework**: Phoenix 1.6.6
- **Frontend**: Phoenix LiveView 0.17.5 (real-time interactive UI)
- **Frontend Styling**: Tailwind CSS (via CDN)
- **Database**: PostgreSQL with Ecto 3.6
- **HTTP Client**: HTTPoison 2.1 (for API calls)

**Key Libraries:**
- `bcrypt_elixir` - Password hashing
- `jason` - JSON encoding/decoding
- `swoosh` - Email handling
- `phoenix_live_dashboard` - Development monitoring
- `phoenix_live_reload` - Hot reload in development
- `esbuild` - Asset bundling
- `gettext` - Internationalization
- `telemetry_metrics` & `telemetry_poller` - Metrics collection

**Database Driver:**
- `postgrex` - PostgreSQL adapter

**Deployment:**
- Docker (multi-stage build process)
- Fly.io (configured via `fly.toml`)

---

### 2. Project Structure

```
spotify-api/
├── lib/
│   ├── spotify_bot/                    # Core application
│   │   ├── application.ex              # OTP application entry point
│   │   ├── repo.ex                     # Database repository
│   │   ├── accounts/                   # User authentication context
│   │   │   ├── user.ex                 # User schema & changesets
│   │   │   ├── user_token.ex           # Session token management
│   │   │   └── user_notifier.ex        # Email notifications
│   │   ├── accounts.ex                 # Accounts business logic
│   │   ├── mailer.ex                   # Email configuration
│   │   └── release.ex                  # Production release tasks
│   │
│   └── spotify_bot_web/                # Web interface layer
│       ├── endpoint.ex                 # Phoenix endpoint config
│       ├── router.ex                   # Route definitions
│       ├── gettext.ex                  # i18n support
│       ├── telemetry.ex                # Telemetry setup
│       ├── controllers/
│       │   ├── user_auth.ex            # Authentication middleware
│       │   ├── page_controller.ex      # Static pages
│       │   ├── user_registration_controller.ex
│       │   ├── user_session_controller.ex
│       │   ├── user_settings_controller.ex
│       │   ├── user_reset_password_controller.ex
│       │   └── live/
│       │       ├── Spotify_live.ex     # MAIN: Spotify streaming UI
│       │       └── Thermostat_live.ex  # Test LiveView component
│       ├── views/                      # Presentation templates
│       └── spotify_bot_web.ex          # Web module definitions
│
├── config/
│   ├── config.exs                      # Base configuration
│   ├── dev.exs                         # Development config
│   ├── prod.exs                        # Production config
│   ├── test.exs                        # Test config
│   └── runtime.exs                     # Runtime configuration
│
├── priv/
│   ├── repo/
│   │   ├── migrations/
│   │   │   └── 20230604213359_create_users_auth_tables.exs
│   │   └── seeds.exs
│   └── static/                         # Static assets
│
├── assets/
│   ├── js/
│   │   └── app.js                      # Main JS entry (SpotifyPlayer hook)
│   ├── vendor/
│   │   └── topbar.js                   # Progress bar
│   └── css/
│       └── app.css
│
├── test/                               # Test suite
├── mix.exs                             # Project manifest & dependencies
├── mix.lock                            # Dependency lock file
├── Dockerfile                          # Multi-stage Docker build
├── fly.toml                            # Fly.io deployment config
└── README.md                           # Project documentation
```

---

### 3. How Spotify Streaming on Repeat Works

#### Architecture Flow:

**1. User Authentication (OAuth 2.0)**
- User clicks "Auth" button
- Redirects to Spotify's OAuth authorization endpoint
- User grants permissions (streaming, read-email, read-private)
- Spotify redirects back with authorization code in URL params

**2. Token Exchange**
- `handle_params/3` detects the authorization code
- Calls `fetch_token/1` which exchanges the code for access tokens
- Stores `access_token` and `refresh_token` in socket state

**3. Track Selection**
- User pastes Spotify track URL (e.g., `https://open.spotify.com/track/3l4eYYvCzqd2Q37KkOBZGC`)
- `handle_event("add-song-url", ...)` triggers
- `url_translator/1` extracts track ID via regex
- `fetch_track_data/2` fetches track metadata from Spotify API
- Stores `track_uri` and `track_name` in state

**4. Device Registration**
- JavaScript hook `SpotifyPlayer` initializes Spotify Web Playback SDK
- SDK generates a `device_id` when player is ready
- Device ID sent back to LiveView via `set-device-id` event
- Stored in socket state

**5. Playback Loop (The Repeat Mechanism)**
```
User clicks "Start Bot"
↓
handle_event("start-timer") → start_timer()
↓
Starts Erlang timer: :erlang.start_timer(2000, self(), :fetch_token)
↓
handle_info({:timeout, _data, :fetch_token})
↓
Calls play_song_on_a_loop(socket)
↓
Starts loop timer: :erlang.start_timer(5000, self(), :loop_song)
↓
handle_info({:timeout, _data, :loop_song})
↓
Increments stream_count: stream_count + 1
↓
Calls play_song(socket) → HTTP PUT to Spotify API
↓
Song plays for ~5 seconds, then loop repeats
↓
Continues until token expires or user clicks "Stop Bot"
```

#### Key Functions:

- `play_song/1`: HTTP PUT request to `https://api.spotify.com/v1/me/player/play?device_id=X`
  - Sends JSON body with track URI and position_ms
  - Handles 204 (success) and 401 (token expired) responses

- `play_song_on_a_loop/1`: Schedules next playback with 5-second timer

- `pause_song/1`: Stops playback with HTTP PUT to `/pause` endpoint

- `start_timer/0`: Initial timer to fetch token (2000ms delay)

- `kill_timer_loop/1`: Cancels timer and pauses song

#### Status Dashboard Real-Time Updates:
- `:tick` handler decrements `expires_in` every 1 second (token countdown)
- Status changes between "Idle", "Loading...", "Streaming", "Paused"
- Stream count increments on each loop iteration

---

### 4. OAuth Token Authentication & Refresh

#### Token Flow:

**1. Initial Authorization Code Exchange** (`fetch_token/1`)
```elixir
POST https://accounts.spotify.com/api/token
Headers:
  - Authorization: Basic <Base64(CLIENT_ID:CLIENT_SECRET)>
  - Content-Type: application/x-www-form-urlencoded
Body:
  grant_type=authorization_code
  &code=<authorization_code>
  &redirect_uri=<REDIRECT_URI>

Response:
  {
    "access_token": "...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "refresh_token": "...",
    "scope": "..."
  }
```

**2. Token Storage in Socket State:**
- `access_token`: Used in subsequent API calls
- `refresh_token`: Stored for renewal when access token expires
- `expires_in`: Countdown timer (decremented every second)

**3. Automatic Token Refresh** (`refresh_token/1`)
- When API returns 401 (Unauthorized), token is expired
- `play_song/1` catches 401 response:
  ```elixir
  {:ok, %{status_code: 401}} ->
    {_, socket} = refresh_token(socket)
    play_song_on_a_loop(socket)
  ```
- Calls `refresh_token/1` which:
  ```elixir
  POST https://accounts.spotify.com/api/token
  Headers:
    - Authorization: Basic <Base64(CLIENT_ID:CLIENT_SECRET)>
    - Content-Type: application/x-www-form-urlencoded
  Body:
    grant_type=refresh_token
    &refresh_token=<refresh_token>
  ```
- Updates socket with new `access_token` and `expires_in`

**4. Manual Refresh** (`handle_event("refresh-token", ...)`)
- User can manually trigger token refresh
- Same process as automatic refresh

**5. Bearer Token Usage in API Calls:**
```elixir
headers = [
  {"Authorization", "Bearer #{socket.assigns.access_token}"},
  {"Content-Type", "application/json"}
]
```

#### Security:
- Tokens are stored in LiveView socket state (in-memory, not persisted)
- Socket uses signed/encrypted session cookies
- CSRF protection enabled via Phoenix
- Refresh tokens are protected with Basic Auth (CLIENT_ID:CLIENT_SECRET)

---

### 5. Main Entry Points & Key Modules

#### Entry Points:

| File | Purpose |
|------|---------|
| `lib/spotify_bot/application.ex` | OTP application start - initializes supervisor tree |
| `lib/spotify_bot_web/endpoint.ex` | Phoenix endpoint - HTTP server setup |
| `lib/spotify_bot_web/router.ex` | Route dispatcher |
| `lib/spotify_bot_web/controllers/live/Spotify_live.ex` | Main UI component |

#### Key Modules:

| Module | Responsibility |
|--------|-----------------|
| `SpotifyBot.Accounts` | User registration, password reset, session management |
| `SpotifyBot.Accounts.User` | User schema with email/password validation |
| `SpotifyBotWeb.UserAuth` | Session/authentication middleware |
| `SpotifyBotWeb.SpotifyLive` | Main Spotify streaming bot UI & logic (650+ lines) |
| `SpotifyBotWeb.Router` | HTTP route definitions |
| `SpotifyBotWeb.Endpoint` | HTTP endpoint & plug pipeline |

#### Supervisory Tree:
```
SpotifyBot.Supervisor (one_for_one strategy)
├── SpotifyBot.Repo (Ecto database connection pool)
├── SpotifyBotWeb.Telemetry (Metrics)
├── SpotifyBot.PubSub (Phoenix PubSub broadcast)
└── SpotifyBotWeb.Endpoint (HTTP server)
```

---

### 6. Configuration Files

#### `config/config.exs` (Base Configuration)
- Ecto repo setup
- Phoenix endpoint configuration
- Mailer setup (Swoosh Local adapter for dev)
- esbuild asset compilation config
- Logger configuration
- Jason JSON library

#### `config/prod.exs` (Production)
- Static manifest caching
- Logger level: info
- SSL/HTTPS configuration (commented, ready to enable)

#### `config/test.exs` (Testing)
- Database: Ecto SQL Sandbox (for test isolation)
- Bcrypt: reduced log rounds (speed up tests)
- Endpoint on localhost:4002
- Mailer: Swoosh Test adapter

#### `fly.toml` (Deployment)
```toml
app = 'spotify-api'
primary_region = 'sjc'
release_command = '/app/bin/migrate'

[env]
PHX_HOST = 'spotify-api.fly.dev'
PORT = 8080

[http_service]
internal_port = 8080
force_https = true
min_machines_running = 0

[[vm]]
memory = '1gb'
cpu_kind = 'shared'
cpus = 1
```

#### `.envrc` (Local Development)
```bash
export PORT=8080
export PHX_HOST="0.0.0.0"
export CLIENT_ID=47b6547d58be4b5199a2d6ffdced8d39
export CLIENT_SECRET=0672593b84b84b58aa550f6124cc4b8f
```

#### Environment Variables Required:
- `CLIENT_ID` - Spotify app ID
- `CLIENT_SECRET` - Spotify app secret
- `REDIRECT_URI` - OAuth callback URL
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Phoenix session encryption key
- `PHX_HOST` - Application host for URL generation

---

### 7. Database Schema

**Single Migration: `20230604213359_create_users_auth_tables.exs`**

```sql
CREATE EXTENSION citext;  -- Case-insensitive text for emails

CREATE TABLE users (
  id bigint PRIMARY KEY,
  email citext NOT NULL UNIQUE,
  hashed_password VARCHAR NOT NULL,
  confirmed_at TIMESTAMP,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE users_tokens (
  id bigint PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
  token bytea NOT NULL,
  context VARCHAR NOT NULL,
  sent_to VARCHAR,
  inserted_at TIMESTAMP NOT NULL
);

CREATE INDEX users_tokens_user_id ON users_tokens(user_id);
CREATE UNIQUE INDEX users_tokens_context_token ON users_tokens(context, token);
```

**Data Stored:**
- User registration & session tokens (not Spotify tokens)
- Spotify OAuth tokens are stored in LiveView socket state (ephemeral)

---

### 8. Deployment Setup

#### Docker Build Process (`Dockerfile`):
1. Multi-stage build (Builder → Runner)
2. Builder stage: Elixir 1.15.7 + OTP 26.2.1
3. Compiles Elixir deps and assets
4. Creates production release
5. Runner stage: Lean Debian image
6. Only copies final release binary
7. Runs as non-root user

#### Fly.io Integration:
- Configured with `fly.toml`
- Region: San Jose (sjc)
- Runs migration on deploy: `/app/bin/migrate`
- Auto-scales machines (min 0, max unlimited)
- HTTPS enforced
- 1 GB memory, 1 shared CPU

#### Deployment Commands:
```bash
fly auth login
fly deploy  # Builds Docker image and deploys
fly secrets set CLIENT_ID=xxx    # Set secrets
fly secrets set CLIENT_SECRET=xxx
fly secrets set REDIRECT_URI=https://your-app.fly.dev
```

---

### 9. Development & Testing

#### Development Features:
- Live reload (code, templates, assets)
- Phoenix LiveDashboard at `/dashboard`
- Mailbox preview at `/dev/mailbox`
- Hot code reloading with Phoenix.CodeReloader

#### Testing:
- Test suite in `test/` directory
- Database: PostgreSQL with test isolation
- Password hashing: Reduced rounds in tests
- Run with: `mix test`

#### Code Quality:
- Format code: `mix format`
- Database operations:
  ```bash
  mix ecto.create      # Create database
  mix ecto.migrate     # Run migrations
  mix ecto.reset       # Drop and recreate
  mix ecto.gen.migration name  # Create migration
  ```

---

### 10. Current Architecture Patterns

**Patterns & Best Practices:**

1. **LiveView-based Real-Time UI**
   - `SpotifyLive` uses Phoenix LiveView for stateful UI
   - WebSocket connection maintains socket state
   - Events trigger `handle_event/3` callbacks
   - Template uses `~H` sigil for HEX templates

2. **Context Pattern (DDD)**
   - `SpotifyBot.Accounts` context isolates user management
   - Separates business logic from web layer

3. **OTP Supervision**
   - Application module defines supervisor tree
   - Proper startup/shutdown sequences
   - Restarts failed processes

4. **Plug Pipeline**
   - Browser pipeline: session, CSRF, current user
   - API pipeline: JSON parsing
   - Authentication middleware: `require_authenticated_user`

5. **Error Handling**
   - HTTP status code matching for API responses
   - Logger calls for debugging (info, error levels)
   - Graceful degradation on API failures

6. **Timer-based Recurring Tasks**
   - Uses Erlang timers (`:erlang.start_timer`)
   - Timers are stored in socket state
   - Enables cancellation via `timer_ref`

7. **JavaScript Hooks**
   - `SpotifyPlayer` hook for SDK initialization
   - Two-way communication: JavaScript → LiveView (`pushEvent`)
   - Data binding: HTML `data` attributes

8. **API Integration Pattern**
   - HTTPoison for HTTP requests
   - Jason for JSON encoding/decoding
   - Bearer token authentication
   - Retry logic via token refresh on 401

---

### Key Insights

1. **No Database Persistence for Spotify Tokens**: Spotify OAuth tokens are ephemeral (stored in LiveView socket state only), not persisted to database. This is memory-efficient but means tokens are lost on disconnect.

2. **Bearer Token Pattern**: All Spotify API calls use OAuth Bearer token authentication via `Authorization: Bearer <token>` header.

3. **Simple Streaming Loop**: Playback is triggered every ~5 seconds via Erlang timers, creating the "repeat on loop" effect.

4. **LiveView as Primary Interface**: Phoenix LiveView replaces traditional HTTP controllers for this interactive bot interface, enabling real-time bidirectional communication.

5. **Token Expiration Handling**: Automatic refresh on 401 response keeps the bot streaming even when tokens expire (typically after 1 hour).

6. **Fly.io Ready**: Project is production-ready with Docker containerization and Fly.io configuration for easy deployment.

---

## Current State Assessment

Your app is a solid **proof-of-concept** with:
- ✅ Working OAuth flow
- ✅ Token refresh logic
- ✅ Real-time UI with LiveView
- ✅ Docker + Fly.io deployment ready
- ✅ Basic user authentication

However, it's currently **single-session focused** (tokens in socket state, timer-based approach, limited error handling).

---

## SaaS-Level Improvements

### 1. ARCHITECTURE CHANGES

#### A. Move from Timer-Based to Background Job Processing

**Current Issue**: Timers run in LiveView process. If user disconnects, streaming stops.

**Solution**: Use **Oban** (Elixir job processing library)

```elixir
# Add to mix.exs
{:oban, "~> 2.17"}

# Create job worker
defmodule SpotifyBot.Workers.StreamWorker do
  use Oban.Worker, queue: :streaming, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "track_uri" => track_uri}}) do
    # Play song logic here
    # Schedule next job in 5 seconds
    %{user_id: user_id, track_uri: track_uri}
    |> new(schedule_in: 5)
    |> Oban.insert()

    :ok
  end
end
```

**Benefits**:
- Streams continue even if user closes browser
- Fault-tolerant (automatic retries)
- Scalable (distributed job processing)
- Can pause/resume streams from database state

---

#### B. Persist Spotify Tokens in Database

**Current Issue**: Tokens stored in socket state = lost on disconnect

**Solution**: Encrypt and store tokens in database

```elixir
# Migration
create table(:spotify_accounts) do
  add :user_id, references(:users, on_delete: :delete_all)
  add :access_token, :binary  # Encrypted
  add :refresh_token, :binary # Encrypted
  add :expires_at, :utc_datetime
  add :spotify_user_id, :string
  timestamps()
end

# Schema with encryption
defmodule SpotifyBot.Accounts.SpotifyAccount do
  use Ecto.Schema

  schema "spotify_accounts" do
    belongs_to :user, SpotifyBot.Accounts.User
    field :access_token, :binary
    field :refresh_token, :binary
    field :expires_at, :utc_datetime
    field :spotify_user_id, :string
    timestamps()
  end

  # Use Cloak or :crypto for encryption at rest
end

# Background token refresh job
defmodule SpotifyBot.Workers.TokenRefreshWorker do
  use Oban.Worker, queue: :token_refresh

  def perform(%{args: %{"account_id" => account_id}}) do
    # Check if token expires in < 5 minutes
    # If so, refresh proactively
  end
end
```

**Benefits**:
- Users don't re-authenticate constantly
- Proactive token refresh (before expiration)
- Audit trail of token usage

---

#### C. Add Streaming Sessions Model

**Current Issue**: Can only stream one track at a time, no history

**Solution**: Create streaming sessions

```elixir
create table(:streaming_sessions) do
  add :user_id, references(:users, on_delete: :delete_all)
  add :track_uri, :string
  add :track_name, :string
  add :device_id, :string
  add :status, :string  # active, paused, stopped, error
  add :stream_count, :integer, default: 0
  add :started_at, :utc_datetime
  add :stopped_at, :utc_datetime
  timestamps()
end
```

**Benefits**:
- Track usage per user
- Show history/analytics
- Enable multiple sessions (queues)
- Better error tracking

---

### 2. SCALABILITY & MULTI-TENANCY

#### A. Add Rate Limiting & Quotas (Free Tier)

```elixir
# Add to mix.exs
{:hammer, "~> 6.1"}  # Rate limiting

# lib/spotify_bot/rate_limiter.ex
defmodule SpotifyBot.RateLimiter do
  use Hammer

  @free_tier_limits %{
    daily_streams: 1000,      # Max 1000 streams/day
    concurrent_sessions: 1,   # Only 1 active session
    max_duration: 60 * 60 * 4 # 4 hours max per session
  }

  def check_limit(user_id, action) do
    case Hammer.check_rate("user:#{user_id}:#{action}", 24 * 60 * 60 * 1000, @free_tier_limits[action]) do
      {:allow, _count} -> :ok
      {:deny, _limit} -> {:error, :rate_limit_exceeded}
    end
  end
end

# In StreamWorker
def perform(%{args: %{"user_id" => user_id}} = job) do
  case RateLimiter.check_limit(user_id, :daily_streams) do
    :ok ->
      # Play song
    {:error, :rate_limit_exceeded} ->
      # Notify user, stop session
      {:cancel, "Daily limit reached"}
  end
end
```

#### B. Connection Pooling & Database Optimization

```elixir
# config/prod.exs
config :spotify_bot, SpotifyBot.Repo,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  queue_target: 50,
  queue_interval: 1000

# Add database indexes
create index(:streaming_sessions, [:user_id, :status])
create index(:streaming_sessions, [:started_at])
create index(:spotify_accounts, [:user_id])
```

---

### 3. RELIABILITY & MONITORING

#### A. Add Error Tracking & Alerting

```elixir
# Add to mix.exs
{:sentry, "~> 10.2"}  # Error tracking
{:appsignal, "~> 2.7"} # Alternative: AppSignal

# config/prod.exs
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: :prod,
  enable_source_code_context: true
```

#### B. Health Checks & Graceful Shutdown

```elixir
# lib/spotify_bot_web/controllers/health_controller.ex
defmodule SpotifyBotWeb.HealthController do
  use SpotifyBotWeb, :controller

  def index(conn, _params) do
    # Check database, Oban, external APIs
    checks = %{
      database: check_database(),
      oban: check_oban(),
      spotify_api: check_spotify_api()
    }

    status = if Enum.all?(checks, fn {_k, v} -> v == :ok end), do: 200, else: 503

    conn
    |> put_status(status)
    |> json(checks)
  end
end

# Add graceful shutdown for Oban jobs
# config/prod.exs
config :spotify_bot, SpotifyBot.Repo,
  pool_size: 10,
  prepare: :unnamed,
  timeout: 15_000
```

#### C. Add Metrics Dashboard

```elixir
# Extend existing telemetry
defmodule SpotifyBotWeb.Telemetry do
  # Add custom metrics
  summary("spotify_bot.streaming.duration")
  counter("spotify_bot.streaming.plays.total")
  counter("spotify_bot.api.errors.total")
  last_value("spotify_bot.users.active.count")
end

# Track metrics in StreamWorker
:telemetry.execute(
  [:spotify_bot, :streaming, :play],
  %{count: 1},
  %{user_id: user_id, track_uri: track_uri}
)
```

---

### 4. USER EXPERIENCE ENHANCEMENTS

#### A. Better Error Handling & User Feedback

```elixir
# In Spotify_live.ex
def handle_info({:streaming_error, reason}, socket) do
  message = case reason do
    :token_expired -> "Your Spotify session expired. Please re-authenticate."
    :device_offline -> "Your device is offline. Please open Spotify and try again."
    :rate_limit_exceeded -> "You've reached your daily free limit (1000 streams). Try again tomorrow!"
    :api_error -> "Spotify API error. We'll retry shortly."
    _ -> "Something went wrong. Please try again."
  end

  socket
  |> put_flash(:error, message)
  |> assign(:status, "Error: #{message}")
  |> noreply()
end
```

#### B. Add User Dashboard & Analytics

```elixir
# New LiveView: lib/spotify_bot_web/controllers/live/dashboard_live.ex
defmodule SpotifyBotWeb.DashboardLive do
  use SpotifyBotWeb, :live_view

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    stats = %{
      total_streams_today: get_streams_today(user_id),
      total_streams_all_time: get_total_streams(user_id),
      remaining_daily_quota: 1000 - get_streams_today(user_id),
      active_sessions: get_active_sessions(user_id),
      favorite_tracks: get_top_tracks(user_id)
    }

    {:ok, assign(socket, stats: stats)}
  end
end
```

#### C. Schedule Streaming Times

```elixir
# Add scheduled_streaming_sessions table
create table(:scheduled_sessions) do
  add :user_id, references(:users)
  add :track_uri, :string
  add :start_time, :time
  add :end_time, :time
  add :days_of_week, {:array, :string}  # ["monday", "friday"]
  add :active, :boolean, default: true
  timestamps()
end

# Cron job to start scheduled sessions
defmodule SpotifyBot.Workers.ScheduledSessionStarter do
  use Oban.Worker, queue: :scheduled

  @impl Oban.Worker
  def perform(_job) do
    # Find sessions that should start now
    # Create streaming session and start StreamWorker
  end
end

# Schedule in application.ex
Oban.insert(%{worker: ScheduledSessionStarter, schedule: "* * * * *"})
```

---

### 5. SECURITY IMPROVEMENTS

#### A. Token Encryption at Rest

```elixir
# Add to mix.exs
{:cloak_ecto, "~> 1.2"}

# lib/spotify_bot/vault.ex
defmodule SpotifyBot.Vault do
  use Cloak.Vault, otp_app: :spotify_bot

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers, [
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_key()}
      ])

    {:ok, config}
  end

  defp decode_key do
    System.get_env("ENCRYPTION_KEY") |> Base.decode64!()
  end
end

# Update SpotifyAccount schema
field :access_token, SpotifyBot.Encrypted.Binary
field :refresh_token, SpotifyBot.Encrypted.Binary
```

#### B. API Rate Limiting per IP

```elixir
# Add plug for rate limiting
defmodule SpotifyBotWeb.RateLimitPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    ip = get_peer_data(conn).address |> :inet.ntoa() |> to_string()

    case Hammer.check_rate("ip:#{ip}", 60_000, 100) do  # 100 req/min
      {:allow, _count} -> conn
      {:deny, _limit} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{error: "Rate limit exceeded"}))
        |> halt()
    end
  end
end

# Add to endpoint.ex
plug SpotifyBotWeb.RateLimitPlug
```

#### C. Secrets Management

```bash
# Use Fly.io secrets, not .envrc
fly secrets set CLIENT_ID=xxx
fly secrets set CLIENT_SECRET=xxx
fly secrets set ENCRYPTION_KEY=$(openssl rand -base64 32)
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)

# Add to runtime.exs
config :spotify_bot, SpotifyBot.Vault,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1",
      key: Base.decode64!(System.fetch_env!("ENCRYPTION_KEY"))
    }
  ]
```

---

### 6. INFRASTRUCTURE & DEVOPS

#### A. Database Backups & Migrations

```bash
# fly.toml
[deploy]
  release_command = "/app/bin/migrate"

# Add backup script
fly postgres backup create -a your-postgres-app

# Scheduled daily backups
fly postgres backup schedule daily -a your-postgres-app
```

#### B. Auto-scaling Configuration

```toml
# fly.toml
[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0  # Scale to zero when idle
  max_machines_running = 5  # Cap for free tier

[[vm]]
  memory = '512mb'  # Reduce to 512MB for free tier
  cpu_kind = 'shared'
  cpus = 1
```

#### C. Logging & Observability

```elixir
# Add structured logging
# lib/spotify_bot_web/controllers/live/Spotify_live.ex
require Logger

def handle_event("start-timer", _, socket) do
  Logger.info("Streaming started",
    user_id: socket.assigns.current_user.id,
    track_uri: socket.assigns.track_uri
  )
  # ...
end

# Add LoggerJSON for structured logs
# mix.exs
{:logger_json, "~> 5.1"}

# config/prod.exs
config :logger, :default_handler,
  formatter: {LoggerJSON.Formatters.GoogleCloud, []}
```

---

### 7. TESTING & CODE QUALITY

#### A. Add Comprehensive Tests

```elixir
# test/spotify_bot/workers/stream_worker_test.exs
defmodule SpotifyBot.Workers.StreamWorkerTest do
  use SpotifyBot.DataCase, async: true
  use Oban.Testing, repo: SpotifyBot.Repo

  alias SpotifyBot.Workers.StreamWorker

  test "plays song and schedules next job" do
    user = insert(:user)
    account = insert(:spotify_account, user: user)
    session = insert(:streaming_session, user: user)

    assert :ok = perform_job(StreamWorker, %{user_id: user.id, session_id: session.id})

    # Assert next job scheduled
    assert_enqueued worker: StreamWorker, args: %{user_id: user.id}
  end
end

# Add factories with ExMachina
# test/support/factory.ex
defmodule SpotifyBot.Factory do
  use ExMachina.Ecto, repo: SpotifyBot.Repo

  def user_factory do
    %SpotifyBot.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      hashed_password: Bcrypt.hash_pwd_salt("password123")
    }
  end
end
```

#### B. Add Code Coverage & CI

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    steps:
      - uses: actions/checkout@v3
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: 1.15.7
          otp-version: 26.2.1
      - run: mix deps.get
      - run: mix test --cover
      - run: mix format --check-formatted
      - run: mix credo
```

---

### 8. DOCUMENTATION & ONBOARDING

#### A. Add API Documentation

```elixir
# Add to mix.exs
{:ex_doc, "~> 0.31", only: :dev}

# Generate docs
mix docs

# Add module documentation
defmodule SpotifyBot.Workers.StreamWorker do
  @moduledoc """
  Background worker that plays a Spotify track on repeat.

  ## Configuration

  Runs every 5 seconds and checks rate limits before playing.

  ## Examples

      iex> StreamWorker.perform(%{user_id: 1, session_id: 123})
      :ok
  """
end
```

#### B. Add User Onboarding Flow

```elixir
# New LiveView: onboarding_live.ex
defmodule SpotifyBotWeb.OnboardingLive do
  # Step 1: Connect Spotify
  # Step 2: Select device
  # Step 3: Choose track
  # Step 4: Start streaming
  # Show tips, limits, FAQs
end
```

---

## Feature Summaries

### 1. ARCHITECTURE CHANGES

**A. Oban Background Jobs**
- **What**: Replace Erlang timers with a persistent job queue system
- **Why**: Right now streaming stops if user closes browser. With Oban, streams run in the background continuously even when user is offline
- **Benefit**: More reliable, can handle failures/retries automatically, and works across server restarts

**B. Database Token Storage**
- **What**: Save Spotify access/refresh tokens in your database (encrypted) instead of just in memory
- **Why**: Currently tokens disappear when user disconnects. Storing them means users stay authenticated across sessions
- **Benefit**: Users don't need to re-authorize with Spotify every time they visit your site

**C. Streaming Sessions Model**
- **What**: Create a database table to track each streaming session (song, start time, play count, status)
- **Why**: Right now you can't see history or manage multiple streams
- **Benefit**: Track usage per user, show analytics, pause/resume sessions, and enforce limits

---

### 2. SCALABILITY & MULTI-TENANCY

**A. Rate Limiting & Quotas**
- **What**: Set limits like "1000 streams/day" or "1 active session at a time" for free users
- **Why**: Prevent abuse and control costs (Spotify API calls, server resources)
- **Benefit**: Keeps your free tier sustainable and opens door for paid tiers later

**B. Database Connection Pooling**
- **What**: Optimize how your app connects to PostgreSQL (pool size, indexes)
- **Why**: As more users join, inefficient database queries will slow everything down
- **Benefit**: App stays fast even with hundreds of concurrent users

---

### 3. RELIABILITY & MONITORING

**A. Error Tracking (Sentry)**
- **What**: Automatically capture and report errors/crashes to a dashboard
- **Why**: Right now if something breaks, you won't know unless a user tells you
- **Benefit**: Get instant alerts when things fail, see stack traces, fix bugs faster

**B. Health Checks**
- **What**: Add a `/health` endpoint that checks if database, jobs, and Spotify API are working
- **Why**: Fly.io and monitoring tools need this to know if your app is healthy
- **Benefit**: Automatic restarts if something goes wrong, better uptime

**C. Metrics Dashboard**
- **What**: Track stats like "total streams today", "API errors per hour", "active users"
- **Why**: You need data to understand how your app is performing
- **Benefit**: Spot trends, optimize performance, make data-driven decisions

---

### 4. USER EXPERIENCE ENHANCEMENTS

**A. Better Error Messages**
- **What**: Show friendly, specific error messages like "Your device is offline" instead of generic errors
- **Why**: Right now users might not understand why streaming failed
- **Benefit**: Less confusion, fewer support requests, happier users

**B. User Dashboard & Analytics**
- **What**: Show users their stats (streams today, remaining quota, favorite tracks)
- **Why**: Users want to see their usage and limits
- **Benefit**: Transparency builds trust, gamification increases engagement

**C. Scheduled Streaming**
- **What**: Let users schedule streams (e.g., "Play this song Mon-Fri at 9am")
- **Why**: Some users want automation without manually starting streams
- **Benefit**: "Set and forget" feature, increases daily active users

---

### 5. SECURITY IMPROVEMENTS

**A. Token Encryption**
- **What**: Encrypt Spotify tokens in database using AES encryption
- **Why**: If someone hacks your database, they shouldn't get raw access tokens
- **Benefit**: Protects user accounts, meets security best practices

**B. IP-Based Rate Limiting**
- **What**: Limit how many requests each IP address can make per minute (e.g., 100/min)
- **Why**: Prevents bots/scrapers from attacking your API
- **Benefit**: Stops DDoS attacks, reduces server costs

**C. Secrets Management**
- **What**: Store sensitive keys (CLIENT_SECRET, encryption keys) in Fly.io secrets, not in code
- **Why**: Right now your `.envrc` has secrets that could leak to GitHub
- **Benefit**: Prevents credential leaks, follows security standards

---

### 6. INFRASTRUCTURE & DEVOPS

**A. Database Backups**
- **What**: Automatically backup your PostgreSQL database daily
- **Why**: If database crashes or gets corrupted, you lose all user data
- **Benefit**: Can restore data after disasters

**B. Auto-Scaling**
- **What**: Configure Fly.io to automatically start/stop servers based on traffic
- **Why**: Right now you pay for servers 24/7 even when no one is using the app
- **Benefit**: Save money by scaling to zero when idle (important for free tier)

**C. Structured Logging**
- **What**: Format logs as JSON with consistent fields (user_id, timestamp, event type)
- **Why**: Right now logs are hard to search and analyze
- **Benefit**: Easier debugging, can send logs to analytics tools

---

### 7. TESTING & CODE QUALITY

**A. Comprehensive Tests**
- **What**: Write automated tests for core features (streaming, token refresh, rate limits)
- **Why**: Right now you don't know if changes break existing features
- **Benefit**: Catch bugs before users do, faster development

**B. CI/CD Pipeline**
- **What**: Auto-run tests on every code change via GitHub Actions
- **Why**: Ensures code quality before deploying to production
- **Benefit**: Prevents broken code from going live

---

### 8. DOCUMENTATION & ONBOARDING

**A. API Documentation**
- **What**: Generate code docs explaining how each module/function works
- **Why**: Makes it easier for you (or contributors) to understand code later
- **Benefit**: Faster development, easier maintenance

**B. User Onboarding**
- **What**: Step-by-step wizard for new users (connect Spotify → pick device → choose song)
- **Why**: Current flow might be confusing for first-time users
- **Benefit**: Higher conversion rate, fewer drop-offs

---

## One-Sentence Summary for Each Feature

| Feature | One-Line Summary |
|---------|------------------|
| **Oban Jobs** | Streams run in background even when user closes browser |
| **DB Token Storage** | Users stay logged in across sessions without re-authenticating |
| **Sessions Model** | Track every stream's history, status, and analytics |
| **Rate Limits** | Prevent abuse with quotas like "1000 streams/day per user" |
| **DB Optimization** | Handle hundreds of users without slowing down |
| **Error Tracking** | Get instant alerts when something breaks |
| **Health Checks** | Auto-restart app if database or APIs fail |
| **Metrics** | See real-time stats like active users and API errors |
| **Better Errors** | Show users why streaming failed in plain English |
| **User Dashboard** | Let users see their stats and remaining quotas |
| **Scheduled Streams** | Let users automate streams (e.g., every weekday at 9am) |
| **Token Encryption** | Protect user tokens from database breaches |
| **IP Rate Limiting** | Stop bots from spamming your API |
| **Secrets Management** | Keep API keys out of code to prevent leaks |
| **Backups** | Recover user data if database crashes |
| **Auto-Scaling** | Scale to zero when idle to save money |
| **Structured Logs** | Make logs searchable and easier to debug |
| **Tests** | Catch bugs before users do |
| **CI/CD** | Auto-test code before deploying |
| **API Docs** | Document code so you understand it later |
| **Onboarding** | Guide new users step-by-step to first stream |

---

## Priority Matrix

| Priority | Feature | Impact | Effort |
|----------|---------|--------|--------|
| **🔴 P0** | Move to Oban background jobs | High | Medium |
| **🔴 P0** | Persist tokens in database (encrypted) | High | Medium |
| **🔴 P0** | Add rate limiting & quotas | High | Low |
| **🟡 P1** | Streaming sessions model | High | Medium |
| **🟡 P1** | Error tracking (Sentry) | Medium | Low |
| **🟡 P1** | Health checks | Medium | Low |
| **🟢 P2** | User dashboard & analytics | Medium | Medium |
| **🟢 P2** | Scheduled streaming | Low | High |
| **🟢 P2** | Comprehensive tests | Medium | High |

---

## Free Tier Monetization Path

Even though you're keeping it free, consider:

1. **"Buy me a coffee" button** (Ko-fi, GitHub Sponsors)
2. **Optional premium features** (future):
   - Higher rate limits
   - Multiple concurrent sessions
   - Advanced scheduling
   - Playlist support
3. **Affiliate links** to Spotify Premium
4. **Anonymous usage analytics** for research/insights

---

## Recommended Next Steps

1. **Week 1**: Add Oban + persist tokens + streaming sessions model
2. **Week 2**: Implement rate limiting + error tracking
3. **Week 3**: Build user dashboard + improve error handling
4. **Week 4**: Add comprehensive tests + CI/CD
5. **Week 5**: Documentation + onboarding flow
6. **Week 6**: Launch beta, gather feedback

---

## Key File References

- **Main Streaming Logic**: `lib/spotify_bot_web/controllers/live/Spotify_live.ex`
- **OAuth & Auth**: `lib/spotify_bot_web/controllers/user_auth.ex`
- **Routes**: `lib/spotify_bot_web/router.ex`
- **Database Schema**: `priv/repo/migrations/20230604213359_create_users_auth_tables.exs`
- **Deployment**: `fly.toml`
- **Docker**: `Dockerfile`
- **Frontend Hooks**: `assets/js/app.js`

---

**Generated**: 2025-11-09
**Review Type**: Architecture & SaaS Readiness Assessment
