defmodule PhoenixLiveInspector.Web.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PhoenixLiveInspector.Web do
    pipe_through :api
    
    get "/sessions", DevToolsController, :list_sessions
    get "/sessions/:id", DevToolsController, :get_session  
    get "/health", DevToolsController, :health
  end

  scope "/" do
    get "/", PhoenixLiveInspector.Web.PageController, :index
  end
end