defmodule Fusion.Chat.EmbedLib do
  @moduledoc """
  Library of embed related functions.
  """
  use FusionMacros, :library
  alias Fusion.Chat.{Embed, EmbedQueries}

  @doc """
  Returns the list of embeds.

  ## Examples

      iex> list_embeds()
      [%Embed{}, ...]

  """
  @spec list_embeds(Fusion.query_args()) :: [Embed.t()]
  def list_embeds(query_args) do
    EmbedQueries.embed_query(query_args)
    |> Fusion.Repo.all()
  end

  @doc """
  Gets a single embed.

  Raises `Ecto.NoResultsError` if the Embed does not exist.

  ## Examples

      iex> get_embed!(123)
      %Embed{}

      iex> get_embed!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_embed!(Fusion.embed_id()) :: Embed.t()
  @spec get_embed!(Fusion.embed_id(),Fusionty.query_args()) :: Embed.t()
  def get_embed!(embed_id, query_args \\ []) do
    (query_args ++ [id: embed_id])
    |> EmbedQueries.embed_query()
    |> Fusion.Repo.one!()
  end

  @doc """
  Gets a single embed. Can take additional arguments for the query.

  Returns nil if the Embed does not exist.

  ## Examples

      iex> get_embed(123)
      %Embed{}

      iex> get_embed(456)
      nil

      iex> get_embed(123, preload: [:extra_embed_data])
      %Embed{}

  """
  @spec get_embed(Fusion.embed_id(),Fusionty.query_args()) :: Embed.t() | nil
  def get_embed(embed_id, query_args \\ []) do
    EmbedQueries.embed_query(query_args ++ [id: embed_id])
    |> Fusion.Repo.one()
  end

  @doc """
  Creates a embed with no checks, use this for system embeds or automated processes; for embed registration make use of `register_embed/1`.

  ## Examples

      iex> create_embed(%{field: value})
      {:ok, %Embed{}}

      iex> create_embed(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_embed(map) :: {:ok, Embed.t()} | {:error, Ecto.Changeset.t()}
  def create_embed(attrs \\ %{}) do
    Embed.changeset(%Embed{}, attrs)
    |> Fusion.Repo.insert()
  end


  @doc """
  Updates a embed.

  ## Examples

      iex> update_embed(embed, %{field: new_value})
      {:ok, %Embed{}}

      iex> update_embed(embed, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_embed(Embed.t(), map) :: {:ok, Embed.t()} | {:error, Ecto.Changeset.t()}
  def update_embed(%Embed{} = embed, attrs) do
    Embed.changeset(embed, attrs, :full)
    |> Fusion.Repo.update()
  end

  @doc """
  Deletes a embed.

  ## Examples

      iex> delete_embed(embed)
      {:ok, %Embed{}}

      iex> delete_embed(embed)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_embed(Embed.t()) :: {:ok, Embed.t()} | {:error, Ecto.Changeset.t()}
  def delete_embed(%Embed{} = embed) do
    Fusion.Repo.delete(embed)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking embed changes.

  ## Examples

      iex> change_embed(embed)
      %Ecto.Changeset{data: %Embed{}}

  """
  @spec change_embed(Embed.t(), map) :: Ecto.Changeset.t()
  def change_embed(%Embed{} = embed, attrs \\ %{}) do
    Embed.changeset(embed, attrs)
  end
end
