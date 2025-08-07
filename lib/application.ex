defmodule PhoenixLiveInspector.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Always start core services - they'll check if enabled
      {Registry, keys: :unique, name: PhoenixLiveInspector.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: PhoenixLiveInspector.DynamicSupervisor},
      {PhoenixLiveInspector.SessionStore, []},
      {Phoenix.PubSub, name: PhoenixLiveInspector.PubSub}
    ]

    opts = [strategy: :one_for_one, name: PhoenixLiveInspector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end