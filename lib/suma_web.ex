defmodule SumaWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use SumaWeb, :controller
      use SumaWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(css js assets webfonts fonts images favicon.png favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: SumaWeb.Layouts]

      import Plug.Conn
      use Gettext, backend: Suma.Gettext

      unquote(verified_routes())
    end
  end

  def schema do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Suma.Account.AuthLib, only: [allow?: 2, allow_any?: 2]
      import Suma.Helpers.SchemaHelper
    end
  end

  def server do
    quote do
      def ok(socket), do: {:ok, socket}
      def noreply(socket), do: {:noreply, socket}
    end
  end

  def queries do
    quote do
      import Ecto.Query, warn: false
      import Suma.Helpers.QueryMacros
      alias Suma.Helpers.QueryHelper
      alias Suma.Repo
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {SumaWeb.Layouts, :app}

      import Suma.Account.AuthLib,
        only: [
          allow?: 2,
          allow_any?: 2,
          allow_all?: 2,
          mount_require_all: 2,
          mount_require_any: 2
        ]

      alias Suma.Helper.StylingHelper

      defguard is_connected?(socket) when socket.transport_pid != nil
      unquote(server())
      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component
      import SumaWeb.CoreComponents

      alias Suma.Helper.StylingHelper
      import Suma.Account.AuthLib, only: [allow?: 2, allow_any?: 2]
      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      alias Suma.Helper.StylingHelper

      import Suma.Account.AuthLib, only: [allow?: 2, allow_any?: 2]

      unquote(html_helpers())
      unquote(server())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import SumaWeb.{CoreComponents, NavComponents, BootstrapComponents}
      use Gettext, backend: Suma.Gettext

      import Suma.Helper.StringHelper, only: [format_number: 1]

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: SumaWeb.Endpoint,
        router: SumaWeb.Router,
        statics: SumaWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
