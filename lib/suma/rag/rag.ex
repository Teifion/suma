defmodule Suma.RAG do
  @moduledoc """

  """

  @default_system_prompt "Using this data: {{vectors}}. Respond to this prompt: {{user_prompt}}"

  def default_system_prompt(), do: @default_system_prompt


  @spec format_prompt(String.t(), list(), String.t() | nil) :: String.t()
  def format_prompt(user_prompt, vectors, system_prompt) do
    system_prompt = system_prompt || @default_system_prompt

    system_prompt
    |> String.replace("{{vectors}}", inspect(vectors))
    |> String.replace("{{user_prompt}}", user_prompt)
  end


  # Contents
  alias Suma.RAG.{Content, ContentLib, ContentQueries}

  @doc false
  @spec content_query(Suma.query_args()) :: Ecto.Query.t()
  defdelegate content_query(args), to: ContentQueries

  @doc section: :content
  @spec list_contents(Suma.query_args()) :: [Content.t]
  defdelegate list_contents(args), to: ContentLib

  @doc section: :content
  @spec get_content!(Content.id()) :: Content.t
  @spec get_content!(Content.id(), Suma.query_args()) :: Content.t
  defdelegate get_content!(content_id, query_args \\ []), to: ContentLib

  @doc section: :content
  @spec get_content(Content.id()) :: Content.t | nil
  @spec get_content(Content.id(), Suma.query_args()) :: Content.t | nil
  defdelegate get_content(content_id, query_args \\ []), to: ContentLib

  @doc section: :content
  @spec create_content(map) :: {:ok, Content.t} | {:error, Ecto.Changeset.t()}
  defdelegate create_content(attrs), to: ContentLib

  @doc section: :content
  @spec update_content(Content, map) :: {:ok, Content.t} | {:error, Ecto.Changeset.t()}
  defdelegate update_content(content, attrs), to: ContentLib

  @doc section: :content
  @spec delete_content(Content.t) :: {:ok, Content.t} | {:error, Ecto.Changeset.t()}
  defdelegate delete_content(content), to: ContentLib

  @doc section: :content
  @spec change_content(Content.t) :: Ecto.Changeset.t()
  @spec change_content(Content.t, map) :: Ecto.Changeset.t()
  defdelegate change_content(content, attrs \\ %{}), to: ContentLib

    # Models
  alias Suma.RAG.{Model, ModelLib, ModelQueries}

  @doc false
  @spec model_query(Suma.query_args()) :: Ecto.Query.t()
  defdelegate model_query(args), to: ModelQueries

  @doc section: :model
  @spec list_models(Suma.query_args()) :: [Model.t]
  defdelegate list_models(args), to: ModelLib

  @doc section: :model
  @spec get_model!(Model.id()) :: Model.t
  @spec get_model!(Model.id(), Suma.query_args()) :: Model.t
  defdelegate get_model!(model_id, query_args \\ []), to: ModelLib

  @doc section: :model
  @spec get_model(Model.id()) :: Model.t | nil
  @spec get_model(Model.id(), Suma.query_args()) :: Model.t | nil
  defdelegate get_model(model_id, query_args \\ []), to: ModelLib

  @doc section: :model
  @spec create_model(map) :: {:ok, Model.t} | {:error, Ecto.Changeset.t()}
  defdelegate create_model(attrs), to: ModelLib

  @doc section: :model
  @spec update_model(Model, map) :: {:ok, Model.t} | {:error, Ecto.Changeset.t()}
  defdelegate update_model(model, attrs), to: ModelLib

  @doc section: :model
  @spec delete_model(Model.t) :: {:ok, Model.t} | {:error, Ecto.Changeset.t()}
  defdelegate delete_model(model), to: ModelLib

  @doc section: :model
  @spec change_model(Model.t) :: Ecto.Changeset.t()
  @spec change_model(Model.t, map) :: Ecto.Changeset.t()
  defdelegate change_model(model, attrs \\ %{}), to: ModelLib

  @doc section: :model
  defdelegate list_model_embeds_for_content(content_id), to: ModelLib
end
