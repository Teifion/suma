defmodule Suma.RAG.EmbedLib do
  @moduledoc """
  Library of embed related functions.
  """
  use SumaMacros, :library
  alias Suma.RAG.{Embed, EmbedQueries, Content, Model}

  @doc """
  Given a user prompt, a model and a client return a list of vectors
  """
  @spec get_nearest_embed(String.t(), Model.t(), Ollama.client()) :: Embed.t()
  def get_nearest_embed(user_prompt, %Model{} = model, client) do
    # Call Ollama to get the embed vectors for this prompt
    {:ok, response} = Ollama.embed(client, model: model.name, input: user_prompt)
    [response_vectors] = response["embeddings"]

    # Now get the closest embed
    closest_embed = EmbedQueries.embed_query(
      where: [model_id: model.id],
      order_by: [{"Vectors", response_vectors}],
      limit: 1
    )
    |> Suma.Repo.one()
  end

  @spec get_nearest_embed_vectors(String.t(), Model.t(), Ollama.client()) :: list()
  def get_nearest_embed_vectors(user_prompt, %Model{} = model, client) do
    get_nearest_embed(user_prompt, model, client)
    |> Map.get(:vectors)
    |> Pgvector.to_list()
  end

  @spec find_non_created_embeds([Content.id()], Model.id()) :: [Content.id()]
  def find_non_created_embeds(content_ids, model_id) when is_list(content_ids) do
    existing_embed_content_ids = list_embeds(
      where: [model_id: model_id, content_id: content_ids],
      select: [:content_id]
    )
    |> Enum.map(fn %{content_id: id} -> id end)

    content_ids
    |> Enum.reject(fn existing_id -> Enum.member?(existing_embed_content_ids, existing_id) end)
  end

  @doc """
  Returns the list of embeds.

  ## Examples

      iex> list_embeds()
      [%Embed{}, ...]

  """
  @spec list_embeds(Suma.query_args()) :: [Embed.t()]
  def list_embeds(query_args) do
    EmbedQueries.embed_query(query_args)
    |> Suma.Repo.all()
  end

  def get_model_content_embed(model_id, content_id) do
    EmbedQueries.embed_query(
      where: [
        model_id: model_id,
        content_id: content_id
      ]
    )
    |> Suma.Repo.one()
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
  @spec get_embed!(Suma.embed_id()) :: Embed.t()
  @spec get_embed!(Suma.embed_id(), Sumaty.query_args()) :: Embed.t()
  def get_embed!(embed_id, query_args \\ []) do
    (query_args ++ [id: embed_id])
    |> EmbedQueries.embed_query()
    |> Suma.Repo.one!()
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
  @spec get_embed(Suma.embed_id(), Sumaty.query_args()) :: Embed.t() | nil
  def get_embed(embed_id, query_args \\ []) do
    EmbedQueries.embed_query(query_args ++ [id: embed_id])
    |> Suma.Repo.one()
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
    |> Suma.Repo.insert()
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
    Embed.changeset(embed, attrs)
    |> Suma.Repo.update()
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
    Suma.Repo.delete(embed)
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
