defmodule PhoenixLiveInspector.Server.WebSocketHandler do
  @moduledoc """
  WebSocket handler for browser extension communication.
  
  Handles real-time communication between the browser extension
  and the LiveView application during development.
  """
  
  @behaviour :cowboy_websocket

  require Logger
  alias PhoenixLiveInspector.SessionStore

  def init(request, _state) do
    # Only allow connections from localhost in development
    case :cowboy_req.peer(request) do
      {{127, 0, 0, 1}, _port} ->
        {:cowboy_websocket, request, %{connected_at: System.system_time(:millisecond)}}
      {{0, 0, 0, 0, 0, 0, 0, 1}, _port} ->
        {:cowboy_websocket, request, %{connected_at: System.system_time(:millisecond)}}
      _other ->
        Logger.warning("DevTools: Rejected non-localhost connection")
        {:ok, :cowboy_req.reply(403, %{}, "Access denied", request), %{}}
    end
  end

  def websocket_init(state) do
    try do
      # Subscribe to DevTools events
      Phoenix.PubSub.subscribe(PhoenixLiveInspector.PubSub, "devtools:events")
      Phoenix.PubSub.subscribe(PhoenixLiveInspector.PubSub, "devtools:sessions")
      
      Logger.info("DevTools: Browser extension connected successfully")
      
      # Send simple initial message to avoid any JSON encoding issues
      message = Jason.encode!(%{
        type: "connected",
        status: "ready",
        timestamp: System.system_time(:millisecond)
      })
      
      {:reply, {:text, message}, state}
    rescue
      error ->
        Logger.error("DevTools: WebSocket init error: #{inspect(error)}")
        {:ok, state}
    end
  end

  def websocket_handle({:text, message}, state) do
    try do
      data = Jason.decode!(message)
      handle_message(data, state)
    rescue
      error ->
        Logger.warning("DevTools: Invalid JSON message: #{inspect(error)}")
        {:ok, state}
    end
  end

  def websocket_handle(_frame, state) do
    {:ok, state}
  end

  def websocket_info({:telemetry_event, event_data}, state) do
    message = Jason.encode!(%{
      type: "liveview_event", 
      event: event_data,
      timestamp: System.system_time(:millisecond)
    })
    {:reply, {:text, message}, state}
  end

  def websocket_info({:session_update, session_data}, state) do
    message = Jason.encode!(%{
      type: "session_update", 
      data: session_data,
      timestamp: System.system_time(:millisecond)
    })
    {:reply, {:text, message}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  def terminate(_reason, _request, _state) do
    Logger.debug("DevTools: Browser extension disconnected")
    :ok
  end

  # Handle incoming messages from browser extension
  defp handle_message(%{"type" => "ping"}, state) do
    pong = Jason.encode!(%{
      type: "pong",
      timestamp: System.system_time(:millisecond)
    })
    {:reply, {:text, pong}, state}
  end

  defp handle_message(%{"type" => "get_sessions"}, state) do
    sessions = SessionStore.get_active_sessions()
    response = Jason.encode!(%{
      type: "sessions",
      data: sessions,
      timestamp: System.system_time(:millisecond)
    })
    {:reply, {:text, response}, state}
  end

  defp handle_message(%{"type" => "get_session", "session_id" => session_id}, state) do
    case SessionStore.get_session(session_id) do
      {:ok, session} ->
        response = Jason.encode!(%{
          type: "session_data",
          data: session,
          timestamp: System.system_time(:millisecond)
        })
        {:reply, {:text, response}, state}
        
      {:error, :not_found} ->
        error = Jason.encode!(%{
          type: "error",
          message: "Session not found",
          timestamp: System.system_time(:millisecond)
        })
        {:reply, {:text, error}, state}
    end
  end

  defp handle_message(unknown, state) do
    Logger.debug("DevTools: Unknown message type: #{inspect(unknown)}")
    {:ok, state}
  end
end