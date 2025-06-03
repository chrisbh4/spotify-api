# 🎵 Spotify Stream Bot

A sophisticated Spotify streaming automation bot built with **Phoenix LiveView** and **Elixir**. This application allows users to authenticate with Spotify, select tracks, and automatically stream them on repeat to boost play counts.

## ✨ Features

- **🔐 Spotify OAuth Authentication** - Secure integration with Spotify Web API
- **🎯 Track URL Input** - Simple interface to add Spotify tracks via URL
- **🤖 Automated Streaming** - Continuous playback automation with configurable intervals
- **📊 Real-time Status Dashboard** - Live monitoring of stream counts, token expiration, and bot status
- **📱 Responsive Design** - Modern, mobile-friendly interface built with Tailwind CSS
- **🔄 Token Management** - Automatic token refresh and session handling
- **👥 User Authentication** - Built-in user registration and session management
- **📈 Stream Analytics** - Track streaming statistics and performance metrics

## 🚀 Quick Start

### Prerequisites

- **Elixir** 1.12+ 
- **Phoenix** 1.6+
- **PostgreSQL** 
- **Node.js** (for asset compilation)
- **Spotify Developer Account** with registered app

### Environment Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd spotify-api
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   cd assets && npm install && cd ..
   ```

3. **Set up environment variables**
   
   Create a `.env` file in your project root:
   ```bash
   # Spotify API Credentials
   CLIENT_ID=your_spotify_client_id
   CLIENT_SECRET=your_spotify_client_secret
   REDIRECT_URI=http://localhost:4000

   # Database
   DATABASE_URL=ecto://username:password@localhost/spotify_bot_dev
   
   # Phoenix
   SECRET_KEY_BASE=your_phoenix_secret_key_base
   PHX_HOST=localhost
   ```

4. **Database setup**
   ```bash
   mix ecto.setup
   ```

5. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

Visit [`http://localhost:4000`](http://localhost:4000) to access the application.

### Spotify App Configuration

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new app or use existing one
3. Add `http://localhost:4000` to Redirect URIs
4. Copy your **Client ID** and **Client Secret** to your environment variables

## 🎯 How to Use

### Step 1: Authentication
Click the **Auth** button to authenticate with your Spotify account. This will redirect you to Spotify's authorization page.

### Step 2: Add a Track
1. Copy a Spotify track URL (e.g., `https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh`)
2. Paste it into the input field
3. Click **Add Song to Bot**

### Step 3: Start Streaming
1. Ensure you have an active Spotify device (desktop app, mobile app, or web player)
2. Click **Start Bot** to begin automated streaming
3. Monitor the status dashboard for real-time updates

### Step 4: Monitor & Control
- View stream count, current track, and token expiration in the status panel
- Use **Stop Bot** to pause streaming
- Re-authenticate when tokens expire

## 🏗️ Architecture

### Tech Stack
- **Backend**: Elixir/Phoenix Framework
- **Frontend**: Phoenix LiveView with Tailwind CSS
- **Database**: PostgreSQL with Ecto
- **Authentication**: Phoenix Authentication (phx.gen.auth)
- **HTTP Client**: HTTPoison
- **Deployment**: Fly.io ready

### Key Components

#### LiveView Controllers
- **`SpotifyLive`** - Main streaming interface and bot controls
- **`ThermostatLive`** - Additional utility module

#### Core Modules
- **`SpotifyBot.Accounts`** - User management and authentication
- **`SpotifyBotWeb.UserAuth`** - Authentication middleware and helpers

#### API Integration
- **Spotify Web API** - Track data, playback control, device management
- **OAuth 2.0 Flow** - Secure token-based authentication

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `CLIENT_ID` | Spotify app client ID | ✅ |
| `CLIENT_SECRET` | Spotify app client secret | ✅ |
| `REDIRECT_URI` | OAuth redirect URI | ✅ |
| `DATABASE_URL` | PostgreSQL connection string | ✅ |
| `SECRET_KEY_BASE` | Phoenix secret key | ✅ |
| `PHX_HOST` | Application host | ✅ |

### Spotify API Scopes
The application requires the following Spotify scopes:
- `user-read-email` - Access user email
- `user-read-private` - Access user profile
- `streaming` - Control playback
- `user-read-currently-playing` - Read current track

## 🚀 Deployment

### Fly.io Deployment

This project is configured for deployment on Fly.io:

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login to Fly**
   ```bash
   fly auth login
   ```

3. **Deploy**
   ```bash
   fly deploy
   ```

### Environment Variables for Production
Set production environment variables:
```bash
fly secrets set CLIENT_ID=your_client_id
fly secrets set CLIENT_SECRET=your_client_secret
fly secrets set REDIRECT_URI=https://your-app.fly.dev
```

## 🧪 Development

### Running Tests
```bash
mix test
```

### Code Formatting
```bash
mix format
```

### Database Operations
```bash
# Reset database
mix ecto.reset

# Create migration
mix ecto.gen.migration migration_name

# Run migrations
mix ecto.migrate
```

### Live Reloading
The development server includes live reloading for:
- Elixir code changes
- Template updates
- CSS/JS asset changes

## 📝 API Reference

### Spotify Web API Endpoints Used

- **Authorization**: `https://accounts.spotify.com/authorize`
- **Token Exchange**: `https://accounts.spotify.com/api/token`
- **Track Info**: `https://api.spotify.com/v1/tracks/{id}`
- **Playback Control**: `https://api.spotify.com/v1/me/player/play`
- **Device List**: `https://api.spotify.com/v1/me/player/devices`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This tool is for educational and personal use only. Please ensure you comply with Spotify's Terms of Service and avoid any activities that may violate their policies. The developers are not responsible for any misuse of this application.

## 🙏 Acknowledgments

- [Phoenix Framework](https://phoenixframework.org/) - Web development framework
- [Spotify Web API](https://developer.spotify.com/documentation/web-api/) - Music streaming API
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS framework
- [Fly.io](https://fly.io/) - Application deployment platform

---

Built with ❤️ using Phoenix LiveView
