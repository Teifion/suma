defmodule Fusion.RAG.Embed do
  @moduledoc false

  use FusionMacros, :schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "rag_embeds" do
    field(:tokens, :integer)
    field(:vectors, Pgvector.Ecto.Vector)

    belongs_to(:model, Fusion.RAG.Model, type: Ecto.UUID)
    belongs_to(:content, Fusion.RAG.Content, type: Ecto.UUID)

    timestamps(type: :utc_datetime)
  end

  @type id :: integer()

  @spec changeset(map()) :: Ecto.Changeset.t()
  @spec changeset(map(), map()) :: Ecto.Changeset.t()
  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(
      attrs,
      ~w(tokens vectors model_id content_id)a
    )
    |> validate_required(
      ~w(tokens vectors model_id content_id)a
    )
  end
end
