defmodule PhoenixLiveInspector.Server.HealthHandler do
  @moduledoc """
  Health check endpoint for the DevTools server.
  """

  def init(request, state) do
    response_data = %{
      status: "ok",
      timestamp: System.system_time(:millisecond),
      version: Application.spec(:live_dev_tools, :vsn) |> to_string()
    }
    
    body = Jason.encode!(response_data)
    
    response = :cowboy_req.reply(200, %{
      "content-type" => "application/json",
      "access-control-allow-origin" => "*"
    }, body, request)
    
    {:ok, response, state}
  end
end