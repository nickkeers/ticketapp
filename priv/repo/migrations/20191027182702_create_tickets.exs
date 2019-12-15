defmodule Naiveticketapp.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :customer_name, :string
      add :payment_ref, :string, default: nil
      add :confirmed, :boolean, default: false
      add :reserved, :boolean, default: false
      add :reserved_until, :utc_datetime
      add :intent_id, :string, default: nil
      add :reservation_id, :string, default: nil

      timestamps()
    end

    create unique_index(:tickets, [:customer_name])
  end
end
