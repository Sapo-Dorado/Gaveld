defmodule Gaveld.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :code, :string
      add :uuid, :string
      add :status, :string
      add :controller, :string, default: nil

      timestamps()
    end

    create unique_index(:games, [:code])
  end
end
