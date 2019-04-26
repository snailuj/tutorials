defmodule Racebook.Repo.Migrations.CreateRaces do
  use Ecto.Migration

  def change do
    create table(:races) do
      add :name, :string
      add :rating, :integer, default: 6
      timestamps
    end
  end
end
