defmodule Gaveld.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
      add :word, :string
      add :type, :string

      timestamps()
    end
    create unique_index(:words, [:word])
  end
end
