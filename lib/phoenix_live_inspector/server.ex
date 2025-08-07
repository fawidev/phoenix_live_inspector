defmodule PhoenixLiveInspector.Server do
  @moduledoc """
  Main DevTools server that handles WebSocket connections from browser extensions.
  
  This server runs only in development and provides real-time communication
  between the browser extension and the LiveView application.
  """
  
  use GenServer
  require Logger

  defstruct [:port, :cowboy_ref, :config]

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    port = config[:port] || 4001
    
    # Start Cowboy HTTP server with WebSocket upgrade support
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/", PhoenixLiveInspector.Server.StatusHandler, []},
        {"/health", PhoenixLiveInspector.Server.HealthHandler, []},
        {"/api/sessions", PhoenixLiveInspector.Server.APIHandler, :sessions},
        {"/api/events", PhoenixLiveInspector.Server.APIHandler, :events},
        {"/devtools/websocket", PhoenixLiveInspector.Server.WebSocketHandler, []},
        {:_, PhoenixLiveInspector.Server.NotFoundHandler, []}
      ]}
    ])

    case :cowboy.start_clear(:phoenix_live_inspector_http, [{:port, port}], %{
      env: %{dispatch: dispatch}
    }) do
      {:ok, cowboy_ref} ->
        Logger.info("PhoenixLiveInspector server started on port #{port}")
        state = %__MODULE__{
          port: port,
          cowboy_ref: cowboy_ref,
          config: config
        }
        {:ok, state}
        
      {:error, reason} ->
        Logger.error("Failed to start PhoenixLiveInspector server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  def terminate(_reason, %__MODULE__{cowboy_ref: cowboy_ref}) do
    :cowboy.stop_listener(cowboy_ref)
    :ok
  end
end