defmodule SumaWeb.Router do
  use SumaWeb, :router

  import SumaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SumaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :maybe_auth do
    plug SumaWeb.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SumaWeb.General do
    pipe_through [:browser]

    live_session :general_index,
      on_mount: [
        {SumaWeb.UserAuth, :mount_current_user}
      ] do
      live "/", HomeLive.Index, :index
      live "/guest", HomeLive.Guest, :index
    end
  end

  scope "/", SumaWeb do
    pipe_through [:browser, :maybe_auth]

    get "/readme", PageController, :readme
  end

  scope "/compare", SumaWeb do
    pipe_through [:browser]

    live_session :compare_index,
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/", CompareLive.Home
      live "/:id", CompareLive.Show
    end
  end

  scope "/models", SumaWeb.Models do
    pipe_through [:browser]

    live_session :user_models,
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated},
        # {SumaWeb.UserAuth, {:authorise, ~w(admin)}}
      ] do
      live "/", IndexLive
      live "/new", NewLive
      live "/:model_name", ShowLive
    end
  end

  scope "/contents", SumaWeb.Contents do
    pipe_through [:browser]

    live_session :user_contents,
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated},
        # {SumaWeb.UserAuth, {:authorise, ~w(admin)}}
      ] do
      live "/", IndexLive
      live "/new", NewLive
      live "/:id", ShowLive
    end
  end

  scope "/admin", SumaWeb.Admin do
    pipe_through [:browser]

    live_session :admin_index,
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated},
        {SumaWeb.UserAuth, {:authorise, "admin"}}
      ] do
      live "/", HomeLive, :index
    end
  end

  scope "/admin/accounts", SumaWeb.Admin.Account do
    pipe_through [:browser]

    live_session :admin_accounts,
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated},
        {SumaWeb.UserAuth, {:authorise, ~w(admin)}}
      ] do
      live "/", IndexLive
      live "/user/new", NewLive
      live "/user/edit/:user_id", ShowLive, :edit
      live "/user/:user_id", ShowLive
    end
  end

  scope "/play", SumaWeb.Play do
    pipe_through [:browser]

    live_session :play_index,
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/new", NewLive.Index, :index
      live "/find", FindLive.Index, :index
      live "/find/:game_id", FindLive.Index, :game
    end

    live_session :play_in_game,
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/ward/:game_id", WardLive.Index, :index
      live "/patients/:game_id", PatientsLive.Index, :index
      live "/desk/:game_id", DeskLive.Index, :index
      live "/job/:game_id/:job_id", JobLive.Index, :index
    end
  end

  scope "/", SumaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{SumaWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/login", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    get "/login/:code", UserSessionController, :login_from_code
    post "/login", UserSessionController, :create
  end

  scope "/", SumaWeb do
    pipe_through [:browser]

    post "/logout", UserSessionController, :delete
    delete "/logout", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{SumaWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/admin", SumaWeb.Admin do
    pipe_through [:browser]
    import Phoenix.LiveDashboard.Router

    live_dashboard("/live_dashboard",
      metrics: Suma.TelemetrySupervisor,
      ecto_repos: [Suma.Repo],
      on_mount: [
        {SumaWeb.UserAuth, :ensure_authenticated},
        {SumaWeb.UserAuth, {:authorise, "admin"}}
      ],
      additional_pages: [
        # live_dashboard_additional_pages
      ]
    )
  end
end
