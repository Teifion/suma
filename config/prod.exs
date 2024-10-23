import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :fusion, FusionWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Fusion.Finch

config :logger,
  format: "$date $time [$level] $metadata $message\n",
  level: :info,
  truncate: :infinity

config :logger, :default_formatter,
  format: "$date $time [$level] $metadata $message\n",
  # metadata: [:error_code, :file, :request_id, :user_id]
  metadata: [:error_code, :request_id, :user_id]

config :logger, :default_handler,
  config: [
    file: ~c"/var/log/fusion/info.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
