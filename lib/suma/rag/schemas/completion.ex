defmodule Suma.RAG.Completion do
  @moduledoc """
  A completion is used to generate completion requests to Ollama
  """

  @type t :: %__MODULE__{}

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :model_name, :string
    field :user_prompt, :string
    field :system_prompt, :string

    field :response, :map

    belongs_to(:content, Suma.RAG.Content, type: Ecto.UUID)
    belongs_to(:model, Suma.RAG.Model, type: Ecto.UUID)

    # Used for comparisons only
    field :variable, :string, default: "model_name"
  end

  def changeset(struct, data \\ %{}) do
    embeds = __MODULE__.__schema__(:embeds)

    fields =
      __MODULE__.__schema__(:fields)
      |> Enum.filter(&(&1 not in embeds))

    Enum.reduce(
      embeds,
      cast(struct, data, fields),
      fn field, changeset -> cast_embed(changeset, field) end
    )
  end
end
