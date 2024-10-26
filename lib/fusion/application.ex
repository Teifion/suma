defmodule Fusion.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Ecto.Migrator,
       repos: Application.fetch_env!(:fusion, :ecto_repos),
       skip: System.get_env("SKIP_MIGRATIONS") == "true"},

      # Start the Telemetry supervisor
      Fusion.TelemetrySupervisor,
      # Start the Ecto repository
      Fusion.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Fusion.PubSub},
      # Start Finch
      {Finch, name: Fusion.Finch},
      # Start the Endpoint (http/https)
      FusionWeb.Endpoint,
      # Start a worker by calling: Fusion.Worker.start_link(arg)
      # {Fusion.Worker, arg}

      Fusion.CacheClusterServer,
      Fusion.RAG.ModelServer,

      # Sups and Registries
      {DynamicSupervisor, strategy: :one_for_one, name: Fusion.ComparisonSupervisor},
      {Registry, [keys: :unique, members: :auto, name: Fusion.LocalComparisonRegistry]},

      # Caches
      add_cache(:user_token_identifier_cache, ttl: :timer.minutes(5)),
      add_cache(:fusion_metadata),
      add_cache(:one_time_login_code, ttl: :timer.seconds(30)),
      add_cache(:user_by_user_id_cache, ttl: :timer.minutes(5)),

      # Login rate limiting
      add_cache(:login_count_ip, ttl: :timer.minutes(5)),
      add_cache(:login_count_user, ttl: :timer.minutes(5))
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fusion.Supervisor]
    start_result = Supervisor.start_link(children, opts)

    Logger.info("Fusion.Supervisor start result: #{Kernel.inspect(start_result)}")

    startup()

    Logger.info("Fusion startup completed")

    start_result
  end

  defp startup() do
    :ok
  end

  @spec add_cache(atom) :: map()
  @spec add_cache(atom, list) :: map()
  defp add_cache(name, opts \\ []) when is_atom(name) do
    %{
      id: name,
      start:
        {Cachex, :start_link,
         [
           name,
           opts
         ]}
    }
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FusionWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
