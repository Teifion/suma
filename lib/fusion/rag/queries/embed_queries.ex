defmodule Fusion.RAG.EmbedQueries do
  @moduledoc false
  use FusionMacros, :queries
  alias Fusion.RAG.Embed
  require Logger
  import Pgvector.Ecto.Query

  @spec embed_query(Fusion.query_args()) :: Ecto.Query.t()
  def embed_query(args) do
    query = from(embeds in Embed)

    query
    |> do_where(id: args[:id])
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
    from(embeds in query,
      where: embeds.id in ^List.wrap(id_list)
    )
  end

  def _where(query, :model_id, model_id) do
    from(embeds in query,
      where: embeds.model_id in ^List.wrap(model_id)
    )
  end

  def _where(query, :content_id, content_id) do
    from(embeds in query,
      where: embeds.content_id in ^List.wrap(content_id)
    )
  end

  def _where(query, :name, name) do
    from(embeds in query,
      where: embeds.name in ^List.wrap(name)
    )
  end

  def _where(query, :name_lower, value) do
    value = value
    |> List.wrap
    |> Enum.map(&String.downcase/1)

    from(embeds in query,
      where: lower(embeds.name) in ^value
    )
  end

  def _where(query, :content, content) do
    from(embeds in query,
      where: embeds.content in ^List.wrap(content)
    )
  end

  def _where(query, :model, model) do
    from(embeds in query,
      where: embeds.model == ^model
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
  def _order_by(query, {"Vectors", vectors}) do
    from(embeds in query,
      order_by: l2_distance(embeds.vectors, ^Pgvector.new(vectors))
    )
  end

  def _order_by(query, "Name (A-Z)") do
    from(embeds in query,
      order_by: [asc: embeds.name]
    )
  end

  def _order_by(query, "Name (Z-A)") do
    from(embeds in query,
      order_by: [desc: embeds.name]
    )
  end

  def _order_by(query, "Newest first") do
    from(embeds in query,
      order_by: [desc: embeds.inserted_at]
    )
  end

  def _order_by(query, "Oldest first") do
    from(embeds in query,
      order_by: [asc: embeds.inserted_at]
    )
  end

  @spec do_preload(Ecto.Query.t(), list | nil) :: Ecto.Query.t()
  defp do_preload(query, _), do: query

  # defp do_preload(query, preloads) do
  #   preloads
  #   |> List.wrap()
  #   |> Enum.reduce(query, fn key, query_acc ->
  #     _preload(query_acc, key)
  #   end)
  # end

  # def _preload(query, :extra_data) do
  #   from(embed in query,
  #     left_join: extra_datas in assoc(embed, :extra_data),
  #     preload: [extra_data: extra_datas]
  #   )
  # end
end
