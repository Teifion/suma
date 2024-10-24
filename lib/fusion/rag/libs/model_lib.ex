defmodule Fusion.RAG.ModelLib do
  @moduledoc """
  Library of model related functions.
  """
  use FusionMacros, :library
  alias Fusion.RAG.{Model, ModelQueries}

  @doc """
  Queries to get the Model id, if it doesn't exist then one is created.
  """
  @spec get_or_add_model(String.t()) :: Model.t()
  def get_or_add_model(%{name: name} = params) do
    case get_model(nil, where: [name: name], limit: 1) do
      nil ->
        {:ok, model} =
          create_model(params)

        model

      model ->
        model
    end
  end


  @doc """
  Returns the list of models.

  ## Examples

      iex> list_models()
      [%Model{}, ...]

  """
  @spec list_models(Fusion.query_args()) :: [Model.t()]
  def list_models(query_args) do
    query_args
    |> ModelQueries.model_query()
    |> Repo.all()
  end

  @doc """
  Gets a single model.

  Raises `Ecto.NoResultsError` if the Model does not exist.

  ## Examples

      iex> get_model!(123)
      %Model{}

      iex> get_model!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_model!(Model.id()) :: Model.t()
  @spec get_model!(Model.id(), Fusion.query_args()) :: Model.t()
  def get_model!(model_id, query_args \\ []) do
    (query_args ++ [id: model_id])
    |> ModelQueries.model_query()
    |> Repo.one!()
  end

  @doc """
  Gets a single model by name.

  Raises `Ecto.NoResultsError` if the Model does not exist.

  ## Examples

      iex> get_model_by_name!("llama3.2")
      %Model{}

      iex> get_model_by_name!("not a model")
      ** (Ecto.NoResultsError)

  """
  @spec get_model_by_name!(Model.name()) :: Model.t()
  @spec get_model_by_name!(Model.name(), Fusion.query_args()) :: Model.t()
  def get_model_by_name!(model_name, query_args \\ []) do
    (query_args ++ [name: model_name])
    |> ModelQueries.model_query()
    |> Repo.one!()
  end

  @doc """
  Gets a single model.

  Returns nil if the Model does not exist.

  ## Examples

      iex> get_model(123)
      %Model{}

      iex> get_model(456)
      nil

  """
  @spec get_model(Model.id()) :: Model.t() | nil
  @spec get_model(Model.id(), Fusion.query_args()) :: Model.t() | nil
  def get_model(model_id, query_args \\ []) do
    (query_args ++ [id: model_id])
    |> ModelQueries.model_query()
    |> Repo.one()
  end

  @doc """
  Creates a model.

  ## Examples

      iex> create_model(%{field: value})
      {:ok, %Model{}}

      iex> create_model(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_model(map) :: {:ok, Model.t()} | {:error, Ecto.Changeset.t()}
  def create_model(attrs) do
    %Model{}
    |> Model.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a model.

  ## Examples

      iex> update_model(model, %{field: new_value})
      {:ok, %Model{}}

      iex> update_model(model, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_model(Model.t(), map) ::
          {:ok, Model.t()} | {:error, Ecto.Changeset.t()}
  def update_model(%Model{} = model, attrs) do
    model
    |> Model.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a model.

  ## Examples

      iex> delete_model(model)
      {:ok, %Model{}}

      iex> delete_model(model)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_model(Model.t()) :: {:ok, Model.t()} | {:error, Ecto.Changeset.t()}
  def delete_model(%Model{} = model) do
    Repo.delete(model)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking model changes.

  ## Examples

      iex> change_model(model)
      %Ecto.Changeset{data: %Model{}}

  """
  @spec change_model(Model.t(), map) :: Ecto.Changeset.t()
  def change_model(%Model{} = model, attrs \\ %{}) do
    Model.changeset(model, attrs)
  end
end
