defmodule PhoenixLiveInspector do
  @moduledoc """
  Phoenix LiveView Inspector - Real-time debugging for Phoenix LiveView applications.

  This library provides comprehensive debugging capabilities for LiveView apps,
  including state inspection, event tracking, and performance monitoring.
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