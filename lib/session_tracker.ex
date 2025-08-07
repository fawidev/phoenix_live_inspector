defmodule PhoenixLiveInspector.SessionTracker do
  @moduledoc """
  Tracks active LiveView sessions and their state changes.
  
  Maintains a registry of all active sessions and provides
  historical tracking of events and state changes.
  """
  
  use GenServer
  require Logger
  
  @table_name :liveview_sessions

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a new LiveView session.
  """
  @spec register_session(String.t(), map()) :: :ok
  def register_session(session_id, initial_state \\ %{}) do
    GenServer.call(__MODULE__, {:register_session, session_id, initial_state})
  end

  @doc """
  Tracks an event for a session.
  """
  @spec track_event(String.t(), map()) :: :ok  
  def track_event(session_id, event_data) do
    GenServer.cast(__MODULE__, {:track_event, session_id, event_data})
  end

  @doc """
  Gets all active sessions.
  """
  @spec get_active_sessions() :: [String.t()]
  def get_active_sessions do
    GenServer.call(__MODULE__, :get_active_sessions)
  end

  @doc """
  Gets session history including events and state changes.
  """
  @spec get_session_history(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_session_history(session_id) do
    GenServer.call(__MODULE__, {:get_session_history, session_id})
  end

  @doc """
  Removes a session from tracking.
  """
  @spec remove_session(String.t()) :: :ok
  def remove_session(session_id) do
    GenServer.call(__MODULE__, {:remove_session, session_id})
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [:named_table, :public, :set])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register_session, session_id, initial_state}, _from, state) do
    session_data = %{
      id: session_id,
      created_at: System.system_time(:millisecond),
      last_activity: System.system_time(:millisecond),
      events: [],
      states: [initial_state],
      metadata: %{}
    }
    
    :ets.insert(@table_name, {session_id, session_data})
    Logger.debug("DevTools: Registered session #{session_id}")
    
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_active_sessions, _from, state) do
    sessions = 
      @table_name
      |> :ets.tab2list()
      |> Enum.map(fn {session_id, _data} -> session_id end)
    
    {:reply, sessions, state}
  end

  @impl true  
  def handle_call({:get_session_history, session_id}, _from, state) do
    case :ets.lookup(@table_name, session_id) do
      [{^session_id, session_data}] ->
        {:reply, {:ok, session_data}, state}
      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:remove_session, session_id}, _from, state) do
    :ets.delete(@table_name, session_id)
    Logger.debug("DevTools: Removed session #{session_id}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:track_event, session_id, event_data}, state) do
    case :ets.lookup(@table_name, session_id) do
      [{^session_id, session_data}] ->
        updated_data = 
          session_data
          |> Map.update!(:events, fn events -> 
            [event_data | events] |> Enum.take(500) # Keep last 500 events
          end)
          |> Map.put(:last_activity, System.system_time(:millisecond))
          
        :ets.insert(@table_name, {session_id, updated_data})
        
      [] ->
        # Auto-register if session doesn't exist
        session_data = %{
          id: session_id,
          created_at: System.system_time(:millisecond),
          last_activity: System.system_time(:millisecond),
          events: [event_data],
          states: [%{}],
          metadata: %{}
        }
        
        :ets.insert(@table_name, {session_id, session_data})
        Logger.debug("DevTools: Auto-registered session #{session_id}")
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:cleanup_old_sessions}, state) do
    current_time = System.system_time(:millisecond)
    timeout = 30 * 60 * 1000 # 30 minutes

    @table_name
    |> :ets.tab2list()
    |> Enum.each(fn {session_id, session_data} ->
      if current_time - session_data.last_activity > timeout do
        :ets.delete(@table_name, session_id)
        Logger.debug("DevTools: Cleaned up inactive session #{session_id}")
      end
    end)

    # Schedule next cleanup
    Process.send_after(self(), {:cleanup_old_sessions}, 60_000)
    
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end