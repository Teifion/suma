defmodule Fusion.RAG.ContentLib do
  @moduledoc """
  Library of content related functions.
  """
  use FusionMacros, :library
  alias Fusion.RAG.{Content, ContentQueries}

  @doc """
  Queries to get the Content id, if it doesn't exist then one is created.
  """
  @spec get_or_add_content(map()) :: Content.t()
  def get_or_add_content(%{name: name} = params) do
    case get_content(nil, where: [name: name], limit: 1) do
      nil ->
        {:ok, content} =
          create_content(params)

        content

      content ->
        content
    end
  end


  @doc """
  Returns the list of contents.

  ## Examples

      iex> list_contents()
      [%Content{}, ...]

  """
  @spec list_contents(Fusion.query_args()) :: [Content.t()]
  def list_contents(query_args) do
    query_args
    |> ContentQueries.content_query()
    |> Repo.all()
  end

  @doc """
  Gets a single content.

  Raises `Ecto.NoResultsError` if the Content does not exist.

  ## Examples

      iex> get_content!(123)
      %Content{}

      iex> get_content!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_content!(Content.id()) :: Content.t()
  @spec get_content!(Content.id(), Fusion.query_args()) :: Content.t()
  def get_content!(content_id, query_args \\ []) do
    (query_args ++ [id: content_id])
    |> ContentQueries.content_query()
    |> Repo.one!()
  end

  @doc """
  Gets a single content.

  Returns nil if the Content does not exist.

  ## Examples

      iex> get_content(123)
      %Content{}

      iex> get_content(456)
      nil

  """
  @spec get_content(Content.id()) :: Content.t() | nil
  @spec get_content(Content.id(), Fusion.query_args()) :: Content.t() | nil
  def get_content(content_id, query_args \\ []) do
    (query_args ++ [id: content_id])
    |> ContentQueries.content_query()
    |> Repo.one()
  end

  @doc """
  Creates a content.

  ## Examples

      iex> create_content(%{field: value})
      {:ok, %Content{}}

      iex> create_content(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_content(map) :: {:ok, Content.t()} | {:error, Ecto.Changeset.t()}
  def create_content(attrs) do
    %Content{}
    |> Content.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a content.

  ## Examples

      iex> update_content(content, %{field: new_value})
      {:ok, %Content{}}

      iex> update_content(content, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_content(Content.t(), map) ::
          {:ok, Content.t()} | {:error, Ecto.Changeset.t()}
  def update_content(%Content{} = content, attrs) do
    content
    |> Content.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a content.

  ## Examples

      iex> delete_content(content)
      {:ok, %Content{}}

      iex> delete_content(content)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_content(Content.t()) :: {:ok, Content.t()} | {:error, Ecto.Changeset.t()}
  def delete_content(%Content{} = content) do
    Repo.delete(content)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking content changes.

  ## Examples

      iex> change_content(content)
      %Ecto.Changeset{data: %Content{}}

  """
  @spec change_content(Content.t(), map) :: Ecto.Changeset.t()
  def change_content(%Content{} = content, attrs \\ %{}) do
    Content.changeset(content, attrs)
  end
end
