defmodule YahtzeePhoenix.Repo.Migrations.CreateRoom do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :token, :string
      add :winner_id, references(:users)

      timestamps()
    end

    create index(:rooms, :token, unique: true)
  end
end
