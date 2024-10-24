defmodule Fusion.RAG.Model do
  @moduledoc false

  use FusionMacros, :schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "rag_models" do
    field(:name, :string)

    timestamps(type: :utc_datetime)
    has_many(:embeds, Fusion.RAG.Embed)
  end

  @type id :: Ecto.UUID.t()
  @type name :: String.t()

  @spec changeset(map()) :: Ecto.Changeset.t()
  @spec changeset(map(), map()) :: Ecto.Changeset.t()
  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(
      attrs,
      ~w(name)a
    )
    |> validate_required(
      ~w(name)a
    )
  end
end
