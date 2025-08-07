# Phoenix LiveView Inspector

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

1. Install from [Chrome Web Store](https://chrome.google.com/webstore) (coming soon)
2. Or load unpacked from `browser_extension/` folder
3. Open Chrome DevTools → "LiveView Inspector" tab

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