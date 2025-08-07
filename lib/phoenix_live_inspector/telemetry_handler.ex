defmodule PhoenixLiveInspector.TelemetryHandler do
  @moduledoc """
  Handles telemetry events from LiveView processes.

  This module captures LiveView lifecycle events and forwards them
  to connected browser extensions via WebSocket.
  """

  require Logger
  alias PhoenixLiveInspector.SessionTracker

  @events [
    [:phoenix, :live_view, :mount, :start],
    [:phoenix, :live_view, :mount, :stop],
    [:phoenix, :live_view, :handle_params, :start],
    [:phoenix, :live_view, :handle_params, :stop],
    [:phoenix, :live_view, :handle_event, :start],
    [:phoenix, :live_view, :handle_event, :stop],
    [:phoenix, :live_view, :render, :start],
    [:phoenix, :live_view, :render, :stop]
  ]

  @doc """
  Attaches telemetry handlers for LiveView events.
  """
  def attach_handlers do
    Enum.each(@events, fn event ->
      :telemetry.attach(
        handler_id(event),
        event,
        &handle_event/4,
        %{}
      )
    end)
  end

  @doc """
  Detaches all LiveView telemetry handlers.
  """
  def detach_handlers do
    Enum.each(@events, fn event ->
      :telemetry.detach(handler_id(event))
    end)
  end

  def handle_event(event, measurements, metadata, _config) do
    session_id = extract_session_id(metadata)

    if session_id do
      # Extract meaningful data from the event
      event_data = %{
        type: format_event_type(event),
        event_name: get_event_name(event, metadata),
        session_id: session_id,
        component: get_component_info(metadata),
        assigns: extract_assigns(metadata),
        params: extract_params(metadata),
        measurements: sanitize_measurements(measurements),
        timestamp: System.system_time(:millisecond),
        duration: get_duration(measurements),
        phase: get_phase(event)
      }

      # Track state changes  
      track_state_change(session_id, event_data)
      
      # Only broadcast meaningful events to reduce noise
      should_broadcast = case event_data.type do
        "handle_event_stop" -> true  # User actions
        "mount_stop" -> true         # Component initialization
        _ -> false                   # Skip start events and render events
      end

      if should_broadcast do
        Logger.info("🎯 Broadcasting event: #{event_data.event_name} with assigns: #{inspect(Map.keys(event_data.assigns))}")
        SessionTracker.track_event(session_id, event_data)
        broadcast_event(event_data)
      end
    end
  rescue
    error ->
      Logger.error("DevTools telemetry error: #{inspect(error)}")
  end

  defp extract_session_id(%{socket: %{id: id}}), do: id
  defp extract_session_id(%{socket: socket}) when is_map(socket) do
    Map.get(socket, :id) || Map.get(socket, :transport_pid)
  end
  defp extract_session_id(_), do: nil

  defp sanitize_metadata(metadata) do
    metadata
    |> Map.drop([:socket])
    |> Map.put(:assigns_keys, get_assigns_keys(metadata))
    |> Map.put(:process_info, get_process_info(metadata))
    |> sanitize_values()
  end

  defp sanitize_values(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> {k, sanitize_values(v)} end)
    |> Map.new()
  end

  defp sanitize_values(data) when is_list(data) do
    Enum.map(data, &sanitize_values/1)
  end

  defp sanitize_values(data) when is_reference(data) do
    inspect(data)
  end

  defp sanitize_values(data) when is_pid(data) do
    inspect(data)
  end

  defp sanitize_values(data) when is_function(data) do
    inspect(data)
  end

  defp sanitize_values(data), do: data

  defp get_assigns_keys(%{socket: %{assigns: assigns}}) when is_map(assigns) do
    Map.keys(assigns)
  end
  defp get_assigns_keys(_), do: []

  defp get_process_info(%{socket: socket}) when is_map(socket) do
    case Map.get(socket, :transport_pid) do
      pid when is_pid(pid) ->
        %{
          pid: inspect(pid),
          memory: get_process_memory(pid),
          message_queue_len: get_message_queue_length(pid)
        }
      _ -> %{}
    end
  end
  defp get_process_info(_), do: %{}

  defp get_process_memory(pid) do
    case Process.info(pid, :memory) do
      {:memory, memory} -> memory
      nil -> 0
    end
  end

  defp get_message_queue_length(pid) do
    case Process.info(pid, :message_queue_len) do
      {:message_queue_len, len} -> len
      nil -> 0
    end
  end

  defp broadcast_event(event_data) do
    Phoenix.PubSub.broadcast(
      PhoenixLiveInspector.PubSub,
      "devtools:events",
      {:telemetry_event, event_data}
    )
  end

  defp extract_assigns(%{socket: %{assigns: assigns}}) when is_map(assigns) do
    assigns
    |> Map.drop([:__changed__, :__temp__, :flash])
    |> sanitize_values()
  end
  defp extract_assigns(_), do: %{}

  defp extract_params(%{params: params}) when is_map(params), do: sanitize_values(params)
  defp extract_params(%{event: event, params: params}) when is_map(params) do
    Map.put(sanitize_values(params), :_event, event)
  end
  defp extract_params(_), do: %{}

  defp get_component_info(%{socket: %{view: view}}) when is_atom(view) do
    %{
      module: view,
      name: get_component_name(view),
      type: :live_view
    }
  end
  defp get_component_info(%{socket: %{__struct__: Phoenix.LiveComponent.Socket} = socket}) do
    %{
      module: Map.get(socket, :component, :unknown),
      name: get_component_name(Map.get(socket, :component, :unknown)),
      type: :live_component,
      id: Map.get(socket, :cid)
    }
  end
  defp get_component_info(_), do: %{module: :unknown, name: "Unknown", type: :unknown}

  defp get_component_name(module) when is_atom(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last()
  end
  defp get_component_name(_), do: "Unknown"

  defp get_event_name([:phoenix, :live_view, :handle_event, _], %{event: event}) do
    "#{event}"  # Just show the actual event name like "increment", "decrement"
  end
  defp get_event_name([:phoenix, :live_view, :mount, phase], metadata) do
    component_name = get_component_info(metadata).name
    "Mount #{component_name} (#{phase})"
  end
  defp get_event_name([:phoenix, :live_view, :handle_params, phase], metadata) do
    component_name = get_component_info(metadata).name
    "Handle Params #{component_name} (#{phase})"
  end
  defp get_event_name([:phoenix, :live_view, :render, phase], metadata) do
    component_name = get_component_info(metadata).name
    "Render #{component_name} (#{phase})"
  end
  defp get_event_name(event, _), do: format_event_type(event)

  defp get_duration(%{duration: duration}) when is_number(duration) do
    duration / 1000 # Convert to milliseconds
  end
  defp get_duration(_), do: nil

  defp get_phase([:phoenix, :live_view, _, phase]), do: phase
  defp get_phase(_), do: :unknown

  defp sanitize_measurements(measurements) do
    measurements
    |> Map.take([:duration, :memory, :reductions])
    |> sanitize_values()
  end

  defp track_state_change(session_id, %{assigns: assigns, phase: :stop, type: type})
       when map_size(assigns) > 0 and type != "render_stop" do
    # Store the latest assigns for state diffing
    Phoenix.PubSub.broadcast(
      PhoenixLiveInspector.PubSub,
      "devtools:state_changes",
      {:state_update, session_id, assigns}
    )
  end
  defp track_state_change(_, _), do: :ok

  defp format_event_type([:phoenix, :live_view, action, phase]) do
    "#{action}_#{phase}"
  end

  defp handler_id(event) do
    event_string = Enum.join(event, "_")
    "phoenix_live_inspector_#{event_string}"
  end
end
