defmodule Suma.RAG.ContentQueries do
  @moduledoc false
  use SumaMacros, :queries
  alias Suma.RAG.Content
  require Logger

  @spec content_query(Suma.query_args()) :: Ecto.Query.t()
  def content_query(args) do
    query = from(contents in Content)

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
    from(contents in query,
      where: contents.id in ^List.wrap(id_list)
    )
  end

  def _where(query, :name, name) do
    from(contents in query,
      where: contents.name in ^List.wrap(name)
    )
  end

  def _where(query, :name_lower, value) do
    value = value
    |> List.wrap
    |> Enum.map(&String.downcase/1)

    from(contents in query,
      where: lower(contents.name) in ^value
    )
  end

  def _where(query, :text, text) do
    from(texts in query,
      where: texts.text in ^List.wrap(text)
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
    from(contents in query,
      order_by: [asc: contents.name]
    )
  end

  def _order_by(query, "Name (Z-A)") do
    from(contents in query,
      order_by: [desc: contents.name]
    )
  end

  def _order_by(query, "Newest first") do
    from(contents in query,
      order_by: [desc: contents.inserted_at]
    )
  end

  def _order_by(query, "Oldest first") do
    from(contents in query,
      order_by: [asc: contents.inserted_at]
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
    from(content in query,
      left_join: embeds in assoc(content, :embed),
      preload: [embed: embeds]
    )
  end
end
