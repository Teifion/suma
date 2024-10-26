defmodule Fusion.RAG.Model do
  @moduledoc false

  use FusionMacros, :schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "rag_models" do
    field(:name, :string)

    # Active means it is both installed and enabled
    field(:active?, :boolean)

    field(:enabled?, :boolean)
    field(:installed?, :boolean)

    field(:details, :map)

    field(:size, :integer)
    field(:ollama_modified_at, :utc_datetime)

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
      ~w(name active? enabled? installed? details size ollama_modified_at)a
    )
    |> validate_required(
      ~w(name active? enabled? installed? details size ollama_modified_at)a
    )
  end
end
