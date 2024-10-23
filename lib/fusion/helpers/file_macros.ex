defmodule FusionMacros do
  @moduledoc """
  A set of macros for defining common file types.

  This can be used in your application as:

      use FusionMacros, :queries
      use FusionMacros, :library
  """

  def queries do
    quote do
      import Ecto.Query, warn: false
      import Fusion.Helpers.QueryMacros
      alias Fusion.Helpers.QueryHelper
      alias Fusion.Repo
    end
  end

  def library do
    quote do
      alias Fusion.Repo
    end
  end

  def schema do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias Fusion.Helpers.SchemaHelper
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
