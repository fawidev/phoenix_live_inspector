defmodule PhoenixLiveInspector.Server.StatusHandler do
  @moduledoc """
  Simple HTTP handler for the DevTools server status page.
  """

  def init(request, state) do
    body = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>LiveView DevTools Server</title>
        <style>
            body { font-family: -apple-system, sans-serif; margin: 40px; }
            .status { color: #22c55e; font-weight: bold; }
            .info { background: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <h1>🛠️ LiveView DevTools Server</h1>
        <p>Status: <span class="status">Running</span></p>
        <div class="info">
            <h3>Connection Info</h3>
            <p><strong>WebSocket:</strong> ws://localhost:4001/devtools/websocket</p>
            <p><strong>API:</strong> http://localhost:4001/api/</p>
        </div>
        <h3>Next Steps:</h3>
        <ol>
            <li>Load the browser extension</li>
            <li>Open your Phoenix LiveView app</li>
            <li>Open Chrome DevTools → "LiveView" tab</li>
        </ol>
    </body>
    </html>
    """
    
    response = :cowboy_req.reply(200, %{
      "content-type" => "text/html"
    }, body, request)
    
    {:ok, response, state}
  end
end