defmodule Naiveticketapp.Tickets.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :customer_name, :string
    field :payment_ref, :string, default: nil
    field :confirmed, :boolean, default: false
    field :intent_id, :string, default: nil

    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:customer_name, :payment_ref, :confirmed, :intent_id])
    |> validate_required([:customer_name])
    |> unique_constraint(:customer_name, message: "customer has already claimed a ticket")
    |> unique_constraint(:intent_id, message: "cannot re-use checkout intent id's")
  end
end
