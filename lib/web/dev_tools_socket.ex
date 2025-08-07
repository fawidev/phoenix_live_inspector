defmodule PhoenixLiveInspector.Web.DevToolsSocket do
  use Phoenix.Socket

  channel "devtools:*", PhoenixLiveInspector.Web.DevToolsChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    # Only allow connections in dev environment
    if Application.get_env(:live_dev_tools, :enabled, false) do
      {:ok, socket}
    else
      :error
    end
  end

  @impl true
  def id(_socket), do: nil
end