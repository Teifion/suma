defmodule Fusion.Chat.EmbedQueries do
  @moduledoc false
  use FusionMacros, :queries
  alias Fusion.Chat.Embed
  require Logger

  import Pgvector.Ecto.Query

  def do_query(vectors) do
    query = from e in Embed,
      order_by: l2_distance(e.vectors, ^Pgvector.new(vectors)),
      limit: 1

    Repo.one(query)
  end

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

  def _where(query, :id, id_list) when is_list(id_list) do
    from(embeds in query,
      where: embeds.id in ^id_list
    )
  end

  def _where(query, :id, id) do
    from(embeds in query,
      where: embeds.id == ^id
    )
  end

  def _where(query, :name, name) do
    from(embeds in query,
      where: embeds.name == ^name
    )
  end

  def _where(query, :name_lower, value) do
    from(embeds in query,
      where: lower(embeds.name) == ^String.downcase(value)
    )
  end

  def _where(query, :email, email) do
    from(embeds in query,
      where: embeds.email == ^email
    )
  end

  def _where(query, :email_lower, value) do
    from(embeds in query,
      where: lower(embeds.email) == ^String.downcase(value)
    )
  end

  def _where(query, :name_or_email, value) do
    from(embeds in query,
      where: embeds.email == ^value or embeds.name == ^value
    )
  end

  def _where(query, :name_like, name) do
    uname = "%" <> name <> "%"

    from(embeds in query,
      where: ilike(embeds.name, ^uname)
    )
  end

  def _where(query, :basic_search, value) do
    from(embeds in query,
      where:
        ilike(embeds.name, ^"%#{value}%") or
          ilike(embeds.email, ^"%#{value}%")
    )
  end

  def _where(query, :inserted_after, timestamp) do
    from(embeds in query,
      where: embeds.inserted_at >= ^timestamp
    )
  end

  def _where(query, :inserted_before, timestamp) do
    from(embeds in query,
      where: embeds.inserted_at < ^timestamp
    )
  end

  def _where(query, :has_group, group_name) do
    from(embeds in query,
      where: ^group_name in embeds.groups
    )
  end

  def _where(query, :not_has_group, group_name) do
    from(embeds in query,
      where: ^group_name not in embeds.groups
    )
  end

  def _where(query, :has_permission, permission_name) do
    from(embeds in query,
      where: ^permission_name in embeds.permissions
    )
  end

  def _where(query, :not_has_permission, permission_name) do
    from(embeds in query,
      where: ^permission_name not in embeds.permissions
    )
  end

  def _where(query, :has_restriction, restriction_name) do
    from(embeds in query,
      where: ^restriction_name in embeds.restrictions
    )
  end

  def _where(query, :not_has_restriction, restriction_name) do
    from(embeds in query,
      where: ^restriction_name not in embeds.restrictions
    )
  end

  def _where(query, :smurf_of, "Smurf"), do: _where(query, :smurf_of, true)
  def _where(query, :smurf_of, "Non-smurf"), do: _where(query, :smurf_of, false)

  def _where(query, :smurf_of, embedid) when is_binary(embedid) do
    from(embeds in query,
      where: embeds.smurf_of_id == ^embedid
    )
  end

  def _where(query, :smurf_of, true) do
    from(embeds in query,
      where: not is_nil(embeds.smurf_of_id)
    )
  end

  def _where(query, :smurf_of, false) do
    from(embeds in query,
      where: is_nil(embeds.smurf_of_id)
    )
  end

  def _where(query, :behaviour_score_gt, score) do
    from(embeds in query,
      where: embeds.behaviour_score > ^score
    )
  end

  def _where(query, :behaviour_score_lt, score) do
    from(embeds in query,
      where: embeds.behaviour_score < ^score
    )
  end

  def _where(query, :last_played_after, timestamp) do
    from(embeds in query,
      where: embeds.last_played_at >= ^timestamp
    )
  end

  def _where(query, :last_played_before, timestamp) do
    from(embeds in query,
      where: embeds.last_played_at < ^timestamp
    )
  end

  def _where(query, :last_login_after, timestamp) do
    from(embeds in query,
      where: embeds.last_login_at >= ^timestamp
    )
  end

  def _where(query, :last_login_before, timestamp) do
    from(embeds in query,
      where: embeds.last_login_at < ^timestamp
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
  defp do_preload(query, nil), do: query

  defp do_preload(query, preloads) do
    preloads
    |> List.wrap()
    |> Enum.reduce(query, fn key, query_acc ->
      _preload(query_acc, key)
    end)
  end

  def _preload(query, :extra_data) do
    from(embed in query,
      left_join: extra_datas in assoc(embed, :extra_data),
      preload: [extra_data: extra_datas]
    )
  end
end
