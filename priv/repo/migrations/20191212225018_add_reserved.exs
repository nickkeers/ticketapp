defmodule Naiveticketapp.Repo.Migrations.AddReserved do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
        add :reserved_by, :text, null: true
    end

    create unique_index(:tickets, [:reserved_by])
  end
end
