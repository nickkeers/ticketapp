defmodule Naiveticketapp.Payments.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :customer_name, :string
    field :payment_ref, :string
    field :confirmed, :boolean
    field :reserved_by, :string

    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:customer_name, :payment_ref, :confirmed, :reserved_by])
    |> validate_required([:customer_name, :payment_ref, :confirmed])
    |> unique_constraint(:customer_name, message: "customer has already claimed a ticket")
    |> unique_constraint(:reserved_by, message: "customer has already reserved a ticket")
  end
end
