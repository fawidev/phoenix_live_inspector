defmodule PhoenixLiveInspector.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_dev_tools

  @session_options [
    store: :cookie,
    key: "_phoenix_live_inspector_key",
    signing_salt: "devtools123",
    same_site: "Lax"
  ]

  socket "/devtools", PhoenixLiveInspector.Web.DevToolsSocket,
    websocket: true,
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :live_dev_tools,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug PhoenixLiveInspector.Web.Router
end