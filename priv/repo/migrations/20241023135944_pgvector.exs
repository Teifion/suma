defmodule Fusion.Repo.Migrations.Pgvector do
  use Ecto.Migration


  # sudo apt-get install postgresql-server-dev-all
  # or
  # git clone https://github.com/pgvector/pgvector.git
  # cd pgvector
  # make
  # sudo make install

  def up() do
    execute "CREATE EXTENSION IF NOT EXISTS vector;"

    create_if_not_exists table(:embeds) do
      add(:title, :string)
      add(:url, :string)
      add(:content, :text)

      add(:tokens, :integer)
      add(:vectors, :vector, size: 3072)

      timestamps(type: :utc_datetime)
    end
  end

  def down() do
    execute "DROP TABLE IF EXISTS embeds;"
    execute "DROP EXTENSION vector"
  end
end
