defmodule Fusion.RAG.Comparison do
  @moduledoc false

  use FusionMacros, :schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "rag_comparisons" do
    field(:name, :string)
    field(:text, :string)

    timestamps(type: :utc_datetime)
    has_many(:embeds, Fusion.RAG.Embed)
  end

  @type id :: Ecto.UUID.t()

  # @spec changeset(map()) :: Ecto.Changeset.t()
  # @spec changeset(map(), map()) :: Ecto.Changeset.t()
  # def changeset(struct, attrs \\ %{}) do
  #   struct
  #   |> cast(
  #     attrs,
  #     ~w(name text)a
  #   )
  #   |> validate_required(
  #     ~w(name text)a
  #   )
  # end
end
