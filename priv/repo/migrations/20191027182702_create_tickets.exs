defmodule Naiveticketapp.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :customer_name, :string
      add :payment_ref, :string
      add :confirmed, :boolean

      timestamps()
    end

    create unique_index(:tickets, [:customer_name])
  end
end
