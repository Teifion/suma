defmodule Fusion.Chat.Embed do
  @moduledoc false

  use FusionMacros, :schema

  schema "embeds" do
    field(:title, :string)
    field(:url, :string)
    field(:content, :string)

    field(:tokens, :integer)

    field(:vectors, Pgvector.Ecto.Vector)

    timestamps(type: :utc_datetime)
  end

  @type id :: integer()

  @spec changeset(map()) :: Ecto.Changeset.t()
  @spec changeset(map(), map()) :: Ecto.Changeset.t()
  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(
      attrs,
      ~w(title url content tokens vectors)a
    )
    |> validate_required(
      ~w(title url content tokens)a
    )
  end
end
