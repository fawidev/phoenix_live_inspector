defmodule PhoenixLiveInspector.Web.DevToolsController do
  use Phoenix.Controller
  
  alias PhoenixLiveInspector.SessionTracker
  
  def list_sessions(conn, _params) do
    sessions = SessionTracker.get_active_sessions()
    json(conn, %{sessions: sessions})
  end

  def get_session(conn, %{"id" => session_id}) do
    case SessionTracker.get_session_history(session_id) do
      {:ok, session_data} ->
        json(conn, session_data)
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Session not found"})
    end
  end

  def health(conn, _params) do
    json(conn, %{
      status: "ok", 
      version: Mix.Project.config()[:version],
      timestamp: System.system_time(:millisecond)
    })
  end
end