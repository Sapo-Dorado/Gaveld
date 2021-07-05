defmodule Gaveld.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :code, :string

      timestamps()
    end

    create unique_index(:games, [:code])
  end
end
