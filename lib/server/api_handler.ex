defmodule PhoenixLiveInspector.Server.APIHandler do
  @moduledoc """
  REST API handler for DevTools data access.
  """

  def init(request, :sessions) do
    handle_sessions(request)
  end

  def init(request, :events) do
    handle_events(request)
  end

  defp handle_sessions(request) do
    sessions = PhoenixLiveInspector.SessionStore.get_active_sessions()
    
    response_data = %{
      sessions: sessions,
      count: length(sessions),
      timestamp: System.system_time(:millisecond)
    }
    
    send_json_response(request, response_data)
  end

  defp handle_events(request) do
    # Get query parameters
    qs = :cowboy_req.parse_qs(request)
    session_id = get_param(qs, "session_id")
    
    events = case session_id do
      nil ->
        []
      session_id ->
        case PhoenixLiveInspector.SessionStore.get_session(session_id) do
          {:ok, session} -> session.events || []
          {:error, _} -> []
        end
    end
    
    response_data = %{
      events: events,
      count: length(events),
      session_id: session_id,
      timestamp: System.system_time(:millisecond)
    }
    
    send_json_response(request, response_data)
  end

  defp send_json_response(request, data) do
    body = Jason.encode!(data)
    
    response = :cowboy_req.reply(200, %{
      "content-type" => "application/json",
      "access-control-allow-origin" => "*",
      "access-control-allow-methods" => "GET, POST, OPTIONS",
      "access-control-allow-headers" => "Content-Type"
    }, body, request)
    
    {:ok, response, %{}}
  end

  defp get_param(qs, key) do
    case List.keyfind(qs, key, 0) do
      {^key, value} -> value
      nil -> nil
    end
  end
end