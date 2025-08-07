defmodule PhoenixLiveInspector.SessionStore do
  @moduledoc """
  Centralized store for LiveView session data and events.
  
  This GenServer maintains state for all active LiveView sessions
  and provides fast access to session data for the DevTools interface.
  """
  
  use GenServer
  require Logger
  
  @table_name :liveview_devtools_sessions
  @max_events_per_session 1000
  @session_timeout :timer.minutes(30)

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register_session(session_id, initial_data \\ %{}) do
    GenServer.cast(__MODULE__, {:register_session, session_id, initial_data})
  end

  def update_session(session_id, updates) do
    GenServer.cast(__MODULE__, {:update_session, session_id, updates})
  end

  def add_event(session_id, event) do
    GenServer.cast(__MODULE__, {:add_event, session_id, event})
  end

  def get_active_sessions() do
    GenServer.call(__MODULE__, :get_active_sessions)
  end

  def get_session(session_id) do
    GenServer.call(__MODULE__, {:get_session, session_id})
  end

  def remove_session(session_id) do
    GenServer.cast(__MODULE__, {:remove_session, session_id})
  end

  # Server Callbacks

  def init(_opts) do
    # Create ETS table for fast session lookups
    :ets.new(@table_name, [
      :set,
      :named_table,
      :public,
      {:read_concurrency, true}
    ])
    
    # Schedule periodic cleanup
    schedule_cleanup()
    
    {:ok, %{}}
  end

  def handle_call(:get_active_sessions, _from, state) do
    sessions = 
      @table_name
      |> :ets.tab2list()
      |> Enum.map(fn {session_id, _data} -> session_id end)
    
    {:reply, sessions, state}
  end

  def handle_call({:get_session, session_id}, _from, state) do
    case :ets.lookup(@table_name, session_id) do
      [{^session_id, session_data}] ->
        {:reply, {:ok, session_data}, state}
      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_cast({:register_session, session_id, initial_data}, state) do
    session_data = %{
      id: session_id,
      created_at: System.system_time(:millisecond),
      last_activity: System.system_time(:millisecond),
      assigns: initial_data[:assigns] || %{},
      events: [],
      metadata: %{
        view: initial_data[:view],
        url: initial_data[:url],
        process_info: initial_data[:process_info] || %{}
      }
    }
    
    :ets.insert(@table_name, {session_id, session_data})
    
    # Broadcast session registration
    Phoenix.PubSub.broadcast(
      PhoenixLiveInspector.PubSub,
      "devtools:sessions",
      {:session_registered, session_id, session_data}
    )
    
    Logger.debug("DevTools: Registered session #{session_id}")
    {:noreply, state}
  end

  def handle_cast({:update_session, session_id, updates}, state) do
    case :ets.lookup(@table_name, session_id) do
      [{^session_id, session_data}] ->
        updated_data = 
          session_data
          |> Map.merge(updates)
          |> Map.put(:last_activity, System.system_time(:millisecond))
        
        :ets.insert(@table_name, {session_id, updated_data})
        
        # Broadcast session update
        Phoenix.PubSub.broadcast(
          PhoenixLiveInspector.PubSub,
          "devtools:sessions",
          {:session_updated, session_id, updated_data}
        )
        
      [] ->
        Logger.warning("DevTools: Attempted to update non-existent session #{session_id}")
    end
    
    {:noreply, state}
  end

  def handle_cast({:add_event, session_id, event}, state) do
    case :ets.lookup(@table_name, session_id) do
      [{^session_id, session_data}] ->
        enriched_event = Map.merge(event, %{
          session_id: session_id,
          timestamp: System.system_time(:millisecond),
          id: generate_event_id()
        })
        
        updated_events = 
          [enriched_event | session_data.events]
          |> Enum.take(@max_events_per_session)
        
        updated_data = 
          session_data
          |> Map.put(:events, updated_events)
          |> Map.put(:last_activity, System.system_time(:millisecond))
        
        :ets.insert(@table_name, {session_id, updated_data})
        
        # Broadcast event
        Phoenix.PubSub.broadcast(
          PhoenixLiveInspector.PubSub,
          "devtools:events",
          {:devtools_event, enriched_event}
        )
        
      [] ->
        # Auto-register session if it doesn't exist
        register_session(session_id)
        add_event(session_id, event)
    end
    
    {:noreply, state}
  end

  def handle_cast({:remove_session, session_id}, state) do
    :ets.delete(@table_name, session_id)
    
    Phoenix.PubSub.broadcast(
      PhoenixLiveInspector.PubSub,
      "devtools:sessions",
      {:session_removed, session_id}
    )
    
    Logger.debug("DevTools: Removed session #{session_id}")
    {:noreply, state}
  end

  def handle_info(:cleanup_sessions, state) do
    current_time = System.system_time(:millisecond)
    
    # Remove sessions that haven't been active for a while
    @table_name
    |> :ets.tab2list()
    |> Enum.each(fn {session_id, session_data} ->
      if current_time - session_data.last_activity > @session_timeout do
        remove_session(session_id)
      end
    end)
    
    schedule_cleanup()
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private Functions

  defp schedule_cleanup() do
    Process.send_after(self(), :cleanup_sessions, :timer.minutes(5))
  end

  defp generate_event_id() do
    System.unique_integer([:positive, :monotonic])
  end
end