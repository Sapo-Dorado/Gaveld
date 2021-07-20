defmodule Gaveld.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string
      add :uid, :string
      add :points, :integer, default: 0
      add :uuid, :string
      add :game_id, references(:games, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:players, [:uid])
    create index(:players, [:game_id])
  end
end
