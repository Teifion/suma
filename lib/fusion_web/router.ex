defmodule FusionWeb.Router do
  use FusionWeb, :router

  import FusionWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {FusionWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :maybe_auth do
    plug FusionWeb.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FusionWeb.General do
    pipe_through [:browser]

    live_session :general_index,
      on_mount: [
        {FusionWeb.UserAuth, :mount_current_user}
      ] do
      live "/", HomeLive.Index, :index
      live "/guest", HomeLive.Guest, :index
    end
  end

  scope "/", FusionWeb do
    pipe_through [:browser, :maybe_auth]

    get "/readme", PageController, :readme
  end

  scope "/compare", FusionWeb do
    pipe_through [:browser]

    live_session :compare_index,
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/", CompareLive.Home
      live "/:id", CompareLive.Show
    end
  end

  scope "/models", FusionWeb.Models do
    pipe_through [:browser]

    live_session :user_models,
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated},
        # {FusionWeb.UserAuth, {:authorise, ~w(admin)}}
      ] do
      live "/", IndexLive
      live "/new", NewLive
      live "/:model_name", ShowLive
    end
  end

  scope "/embeds", FusionWeb.Embeds do
    pipe_through [:browser]

    live_session :user_embeds,
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated},
        # {FusionWeb.UserAuth, {:authorise, ~w(admin)}}
      ] do
      live "/", IndexLive
      live "/:id", ShowLive
    end
  end

  scope "/admin", FusionWeb.Admin do
    pipe_through [:browser]

    live_session :admin_index,
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated},
        {FusionWeb.UserAuth, {:authorise, "admin"}}
      ] do
      live "/", HomeLive, :index
    end
  end

  scope "/admin/accounts", FusionWeb.Admin.Account do
    pipe_through [:browser]

    live_session :admin_accounts,
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated},
        {FusionWeb.UserAuth, {:authorise, ~w(admin)}}
      ] do
      live "/", IndexLive
      live "/user/new", NewLive
      live "/user/edit/:user_id", ShowLive, :edit
      live "/user/:user_id", ShowLive
    end
  end

  scope "/play", FusionWeb.Play do
    pipe_through [:browser]

    live_session :play_index,
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/new", NewLive.Index, :index
      live "/find", FindLive.Index, :index
      live "/find/:game_id", FindLive.Index, :game
    end

    live_session :play_in_game,
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/ward/:game_id", WardLive.Index, :index
      live "/patients/:game_id", PatientsLive.Index, :index
      live "/desk/:game_id", DeskLive.Index, :index
      live "/job/:game_id/:job_id", JobLive.Index, :index
    end
  end

  scope "/", FusionWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{FusionWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/login", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    get "/login/:code", UserSessionController, :login_from_code
    post "/login", UserSessionController, :create
  end

  scope "/", FusionWeb do
    pipe_through [:browser]

    delete "/logout", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{FusionWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/admin", FusionWeb.Admin do
    pipe_through [:browser]
    import Phoenix.LiveDashboard.Router

    live_dashboard("/live_dashboard",
      metrics: Fusion.TelemetrySupervisor,
      ecto_repos: [Fusion.Repo],
      on_mount: [
        {FusionWeb.UserAuth, :ensure_authenticated},
        {FusionWeb.UserAuth, {:authorise, "admin"}}
      ],
      additional_pages: [
        # live_dashboard_additional_pages
      ]
    )
  end
end
