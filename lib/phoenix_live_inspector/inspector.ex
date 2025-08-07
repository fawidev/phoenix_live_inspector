defmodule PhoenixLiveInspector.Inspector do
  @moduledoc """
  Process introspection utilities for LiveView debugging.
  
  Provides safe methods to inspect LiveView process state
  without interfering with application execution.
  """

  @doc """
  Safely extracts state from a LiveView process.
  
  Returns process assigns, metadata, and other debugging info.
  """
  @spec get_state(pid()) :: {:ok, map()} | {:error, term()}
  def get_state(pid) when is_pid(pid) do
    try do
      case Process.info(pid, [:dictionary, :memory, :message_queue_len]) do
        nil ->
          {:error, :process_not_alive}
        
        info ->
          state = extract_liveview_state(pid, info)
          {:ok, state}
      end
    rescue
      error -> {:error, error}
    end
  end

  @doc """
  Gets a diff between two state snapshots.
  """
  @spec state_diff(map(), map()) :: map()
  def state_diff(old_state, new_state) do
    %{
      added: Map.drop(new_state, Map.keys(old_state)),
      removed: Map.drop(old_state, Map.keys(new_state)),
      changed: get_changed_keys(old_state, new_state),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp extract_liveview_state(pid, process_info) do
    dictionary = Keyword.get(process_info, :dictionary, [])
    memory = Keyword.get(process_info, :memory, 0)
    queue_len = Keyword.get(process_info, :message_queue_len, 0)

    %{
      pid: inspect(pid),
      assigns: get_assigns_from_dictionary(dictionary),
      memory_bytes: memory,
      message_queue_length: queue_len,
      process_dictionary: sanitize_dictionary(dictionary),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp get_assigns_from_dictionary(dictionary) do
    case Keyword.get(dictionary, :"$assigns") do
      assigns when is_map(assigns) ->
        sanitize_assigns(assigns)
      _ ->
        %{}
    end
  end

  defp sanitize_assigns(assigns) do
    assigns
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      sanitized_value = sanitize_value(value)
      Map.put(acc, key, sanitized_value)
    end)
  end

  defp sanitize_value(value) when is_function(value) do
    "#Function<#{inspect(value)}>"
  end
  defp sanitize_value(value) when is_pid(value) do
    "#PID<#{inspect(value)}>"
  end
  defp sanitize_value(value) when is_reference(value) do
    "#Reference<#{inspect(value)}>"
  end
  defp sanitize_value(value) when is_port(value) do
    "#Port<#{inspect(value)}>"
  end
  defp sanitize_value(value) when is_map(value) do
    if map_size(value) > 50 do
      "#LargeMap<#{map_size(value)} keys>"
    else
      Map.new(value, fn {k, v} -> {k, sanitize_value(v)} end)
    end
  end
  defp sanitize_value(value) when is_list(value) do
    if length(value) > 100 do
      "#LongList<#{length(value)} items>"
    else
      Enum.map(value, &sanitize_value/1)
    end
  end
  defp sanitize_value(value), do: value

  defp sanitize_dictionary(dictionary) do
    dictionary
    |> Enum.reject(fn {key, _} -> key == :"$assigns" end)
    |> Enum.into(%{})
  end

  defp get_changed_keys(old_state, new_state) do
    common_keys = 
      MapSet.intersection(
        MapSet.new(Map.keys(old_state)),
        MapSet.new(Map.keys(new_state))
      )

    common_keys
    |> Enum.filter(fn key ->
      Map.get(old_state, key) != Map.get(new_state, key)
    end)
    |> Enum.into(%{}, fn key ->
      {key, %{old: Map.get(old_state, key), new: Map.get(new_state, key)}}
    end)
  end
end