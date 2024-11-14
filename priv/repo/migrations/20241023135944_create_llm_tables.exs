defmodule Suma.Repo.Migrations.CreateLLMTables do
  use Ecto.Migration


  # sudo apt-get install postgresql-server-dev-all
  # or
  # git clone https://github.com/pgvector/pgvector.git
  # cd pgvector
  # make
  # sudo make install

  def up() do
    execute "CREATE EXTENSION IF NOT EXISTS vector;"

    create_if_not_exists table(:rag_contents, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false)
      add(:name, :string)
      add(:text, :text)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:rag_models, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false)
      add(:name, :string)

      add(:active?, :boolean)
      add(:enabled?, :boolean)
      add(:installed?, :boolean)

      add(:details, :map)
      add(:size, :bigint)
      add(:ollama_modified_at, :utc_datetime)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:rag_embeds, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false)
      add(:tokens, :integer)
      add(:vectors, :vector, size: 4096)

      add(:model_id, references(:rag_models, on_delete: :nothing, type: :uuid), type: :uuid)
      add(:content_id, references(:rag_contents, on_delete: :nothing, type: :uuid), type: :uuid)

      timestamps(type: :utc_datetime)
    end
  end

  def down() do
    execute "DROP TABLE IF EXISTS rag_embeds;"
    execute "DROP TABLE IF EXISTS rag_models;"
    execute "DROP TABLE IF EXISTS rag_contents;"
    execute "DROP EXTENSION vector"
  end
end
