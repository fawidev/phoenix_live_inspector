defmodule PhoenixLiveInspector.Web.PageController do
  use Phoenix.Controller
  
  def index(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html>
    <head>
        <title>LiveView DevTools</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
            .header { color: #6B46C1; margin-bottom: 30px; }
            .status { background: #F0FDF4; border: 1px solid #BBF7D0; padding: 15px; border-radius: 8px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🛠️ LiveView DevTools</h1>
            <p>Real-time debugging for Phoenix LiveView applications</p>
        </div>
        
        <div class="status">
            <h3>✅ Server Running</h3>
            <p>DevTools server is active and listening for connections.</p>
            <p><strong>WebSocket:</strong> ws://localhost:4001/devtools</p>
            <p><strong>API:</strong> http://localhost:4001/api</p>
        </div>

        <h3>Next Steps:</h3>
        <ol>
            <li>Install the browser extension</li>
            <li>Add PhoenixLiveInspector to your Phoenix app</li>
            <li>Open Chrome DevTools to see the LiveView panel</li>
        </ol>
    </body>
    </html>
    """)
  end
end