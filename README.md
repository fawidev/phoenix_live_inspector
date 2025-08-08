# Phoenix LiveView Inspector

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_live_inspector.svg)](https://hex.pm/packages/phoenix_live_inspector)
[![Documentation](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/phoenix_live_inspector)
[![License](https://img.shields.io/hexpm/l/phoenix_live_inspector.svg)](https://github.com/fawidev/phoenix_live_inspector/blob/main/LICENSE)
[![Downloads](https://img.shields.io/hexpm/dt/phoenix_live_inspector.svg)](https://hex.pm/packages/phoenix_live_inspector)

Real-time debugging and state inspection for Phoenix LiveView applications.

## Features

🔍 **State Inspector** - View real-time `@assigns` values
🎯 **Event Tracking** - Monitor user interactions and LiveView events  
⚡ **Performance Metrics** - Track render times and memory usage
🌐 **Browser Extension** - Chrome DevTools integration

## Installation

Add to your LiveView project's `mix.exs`:

```elixir
def deps do
  [
    # ... your existing deps
    {:phoenix_live_inspector, "~> 0.1.0", only: :dev}
  ]
end
```

## Quick Start

Add **one line** to your `application.ex`:

```elixir
def start(_type, _args) do
  children = [
    # ... your existing children
  ]
  
  # Start Phoenix LiveView Inspector (one line integration)
  if Mix.env() == :dev do
    PhoenixLiveInspector.start()
  end
  
  opts = [strategy: :one_for_one, name: YourApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Browser Extension

### Option 1: Chrome Web Store (Recommended)
Install from [Chrome Web Store](https://chrome.google.com/webstore) (coming soon)

### Option 2: Local Development Setup

**Load the extension from this repository:**

1. **Clone this repository**:
   ```bash
   git clone https://github.com/fawidev/phoenix_live_inspector.git
   cd phoenix_live_inspector
   ```

2. **Open Chrome Extensions page**:
   - Go to `chrome://extensions/` in Chrome
   - Enable **Developer mode** (toggle in top-right corner)

3. **Load the extension**:
   - Click **"Load unpacked"** button
   - Navigate to and select the `browser_extension/` folder in this repo
   - The Phoenix LiveView Inspector extension will appear in your extensions list

4. **Verify installation**:
   - Look for the Phoenix LiveView Inspector icon in your Chrome toolbar
   - Open any webpage and press F12 to open DevTools
   - You should see a **"LiveView Inspector"** tab in the DevTools panel

5. **Start debugging**:
   - Run your Phoenix LiveView app with the library installed
   - Navigate to your app (e.g., `http://localhost:4000`)
   - Open DevTools → "LiveView Inspector" tab
   - Interact with your LiveView app to see real-time events and state changes

## Usage

1. **Start your Phoenix app**: `mix phx.server`
2. **Open DevTools**: F12 → "LiveView Inspector" tab
3. **Interact with your app**: Click buttons, submit forms, etc.
4. **Debug in real-time**: See state updates and events

## Security

- ✅ **Development only**: Automatically disabled in production  
- ✅ **Localhost only**: WebSocket server restricted to localhost
- ✅ **Zero production impact**: No dependencies or overhead in releases

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Submit a pull request

---

**Made with ❤️ for the Phoenix LiveView community**