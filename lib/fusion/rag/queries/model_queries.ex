defmodule Fusion.RAG.ModelQueries do
  @moduledoc false
  use FusionMacros, :queries
  alias Fusion.RAG.Model
  require Logger

  @spec model_query(Fusion.query_args()) :: Ecto.Query.t()
  def model_query(args) do
    query = from(models in Model)

    query
    |> do_where(id: args[:id])
    |> do_where(name: args[:name])
    |> do_where(args[:where])
    |> do_preload(args[:preload])
    |> do_order_by(args[:order_by])
    |> QueryHelper.query_select(args[:select])
    |> QueryHelper.limit_query(args[:limit] || 50)
  end

  @spec do_where(Ecto.Query.t(), list | map | nil) :: Ecto.Query.t()
  defp do_where(query, nil), do: query

  defp do_where(query, params) do
    params
    |> Enum.reduce(query, fn {key, value}, query_acc ->
      _where(query_acc, key, value)
    end)
  end

  @spec _where(Ecto.Query.t(), atom, any()) :: Ecto.Query.t()
  def _where(query, _, ""), do: query
  def _where(query, _, nil), do: query

  def _where(query, :id, id_list) do
    from(models in query,
      where: models.id in ^List.wrap(id_list)
    )
  end

  def _where(query, :name, name) do
    from(models in query,
      where: models.name in ^List.wrap(name)
    )
  end

  def _where(query, :name_lower, value) do
    value = value
    |> List.wrap
    |> Enum.map(&String.downcase/1)

    from(models in query,
      where: lower(models.name) in ^value
    )
  end

  def _where(query, :active?, active?) do
    from(models in query,
      where: models.active? == ^active?
    )
  end

  @spec do_order_by(Ecto.Query.t(), list | nil) :: Ecto.Query.t()
  defp do_order_by(query, nil), do: query

  defp do_order_by(query, params) do
    params
    |> List.wrap()
    |> Enum.reduce(query, fn key, query_acc ->
      _order_by(query_acc, key)
    end)
  end

  @spec _order_by(Ecto.Query.t(), any()) :: Ecto.Query.t()
  def _order_by(query, "Name (A-Z)") do
    from(models in query,
      order_by: [asc: models.name]
    )
  end

  def _order_by(query, "Name (Z-A)") do
    from(models in query,
      order_by: [desc: models.name]
    )
  end

  def _order_by(query, "Newest first") do
    from(models in query,
      order_by: [desc: models.inserted_at]
    )
  end

  def _order_by(query, "Oldest first") do
    from(models in query,
      order_by: [asc: models.inserted_at]
    )
  end

  @spec do_preload(Ecto.Query.t(), list | nil) :: Ecto.Query.t()
  defp do_preload(query, preloads) do
    preloads
    |> List.wrap()
    |> Enum.reduce(query, fn key, query_acc ->
      _preload(query_acc, key)
    end)
  end

  def _preload(query, :embeds) do
    from(model in query,
      left_join: embeds in assoc(model, :embed),
      preload: [embed: embeds]
    )
  end
end
