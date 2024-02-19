defmodule TodoAppWeb.Router do
  use TodoAppWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TodoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TodoAppWeb do
    pipe_through :browser

    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  overrides: [
                    TodoAppWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    sign_out_route AuthController
    auth_routes_for TodoApp.Accounts.User, to: AuthController
    reset_route []

    get "/", PageController, :home

    ash_authentication_live_session :authentication_required,
      on_mount: {TodoAppWeb.LiveUserAuth, :live_user_required} do
      live "/todo", EntriesLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TodoAppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:todo_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TodoAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
