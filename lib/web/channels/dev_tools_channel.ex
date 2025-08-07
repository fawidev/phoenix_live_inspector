defmodule PhoenixLiveInspector.Web.DevToolsChannel do
  use Phoenix.Channel
  
  alias PhoenixLiveInspector.{SessionTracker, Inspector}
  require Logger

  @impl true
  def join("devtools:browser", _payload, socket) do
    # Subscribe to telemetry events
    Phoenix.PubSub.subscribe(PhoenixLiveInspector.PubSub, "devtools:events")
    
    Logger.debug("DevTools browser extension connected")
    {:ok, %{connected: true}, socket}
  end

  @impl true
  def join("devtools:" <> _session_id, _payload, socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @impl true
  def handle_in("get_sessions", _payload, socket) do
    sessions = SessionTracker.get_active_sessions()
    {:reply, {:ok, %{sessions: sessions}}, socket}
  end

  @impl true
  def handle_in("get_session_history", %{"session_id" => session_id}, socket) do
    case SessionTracker.get_session_history(session_id) do
      {:ok, history} ->
        {:reply, {:ok, history}, socket}
      {:error, :not_found} ->
        {:reply, {:error, %{reason: "session not found"}}, socket}
    end
  end

  @impl true
  def handle_in("inspect_process", %{"pid" => pid_string}, socket) do
    case parse_pid(pid_string) do
      {:ok, pid} ->
        case Inspector.get_state(pid) do
          {:ok, state} ->
            {:reply, {:ok, state}, socket}
          {:error, reason} ->
            {:reply, {:error, %{reason: inspect(reason)}}, socket}
        end
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  @impl true
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{pong: true, timestamp: System.system_time(:millisecond)}}, socket}
  end

  @impl true
  def handle_in(_event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event"}}, socket}
  end

  @impl true
  def handle_info({:telemetry_event, event_data}, socket) do
    push(socket, "telemetry_event", event_data)
    {:noreply, socket}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp parse_pid("#PID<" <> pid_string) do
    case String.split(String.trim_trailing(pid_string, ">"), ".") do
      [node_part | rest] when length(rest) >= 2 ->
        try do
          pid = :erlang.list_to_pid(String.to_charlist("#PID<#{pid_string}"))
          {:ok, pid}
        rescue
          _ -> {:error, "invalid pid format"}
        end
      _ ->
        {:error, "invalid pid format"}
    end
  end

  defp parse_pid(pid_string) when is_binary(pid_string) do
    case String.starts_with?(pid_string, "<") do
      true -> parse_pid("#PID" <> pid_string)
      false -> parse_pid("#PID<" <> pid_string <> ">")
    end
  end

  defp parse_pid(_), do: {:error, "invalid pid"}
end