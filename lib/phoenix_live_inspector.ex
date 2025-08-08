defmodule PhoenixLiveInspector do
  @moduledoc """
  Phoenix LiveView Inspector - Real-time debugging for Phoenix LiveView applications.

  This library provides comprehensive debugging capabilities for LiveView apps,
  including state inspection, event tracking, and performance monitoring.

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

  ## Browser Extension Setup

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

  ## Security

  - ✅ **Development only**: Automatically disabled in production  
  - ✅ **Localhost only**: WebSocket server restricted to localhost
  - ✅ **Zero production impact**: No dependencies or overhead in releases
  """

  alias PhoenixLiveInspector.{Inspector, SessionTracker, TelemetryHandler}

  @doc """
  Starts the Phoenix LiveView Inspector for the current application.
  
  Should only be used in development environments.
  
  ## Options
  
  * `:port` - WebSocket server port (default: 4001)
  * `:enabled` - Enable/disable inspector (default: Mix.env() == :dev)
  
  ## Examples
  
      # Start with defaults
      PhoenixLiveInspector.start()
      
      # Custom port
      PhoenixLiveInspector.start(port: 4002)
      
  """
  @spec start(keyword()) :: :ok | {:error, term()}
  def start(opts \\ []) do
    config = build_config(opts)
    
    if config.enabled do
      # Start telemetry handlers for LiveView events
      TelemetryHandler.attach_handlers()
      
      # Start the Inspector server in a supervised process
      case DynamicSupervisor.start_child(
        PhoenixLiveInspector.DynamicSupervisor,
        {PhoenixLiveInspector.Server, config}
      ) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        error -> error
      end
    else
      :ok
    end
  end

  @doc """
  Stops Phoenix LiveView Inspector and cleans up resources.
  """
  @spec stop() :: :ok
  def stop do
    TelemetryHandler.detach_handlers()
    :ok
  end

  @doc """
  Gets current configuration for Inspector.
  """
  @spec config() :: map()
  def config do
    Application.get_env(:phoenix_live_inspector, :config, %{})
  end

  @doc """
  Manually inspects a LiveView process for debugging.
  
  ## Examples
  
      PhoenixLiveInspector.inspect_process(pid)
      
  """
  @spec inspect_process(pid()) :: {:ok, map()} | {:error, term()}
  def inspect_process(pid) when is_pid(pid) do
    Inspector.get_state(pid)
  end

  defp build_config(opts) do
    defaults = %{
      enabled: Mix.env() == :dev,
      port: 4001,
      host: "localhost"
    }
    
    config = 
      :phoenix_live_inspector
      |> Application.get_env(:config, %{})
      |> Map.merge(Enum.into(opts, %{}))
    
    Map.merge(defaults, config)
  end
end