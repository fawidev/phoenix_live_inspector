defmodule PhoenixLiveInspector.Server.NotFoundHandler do
  @moduledoc """
  404 handler for the DevTools server.
  """

  def init(request, state) do
    response = :cowboy_req.reply(404, %{
      "content-type" => "text/plain"
    }, "Not Found", request)
    
    {:ok, response, state}
  end
end