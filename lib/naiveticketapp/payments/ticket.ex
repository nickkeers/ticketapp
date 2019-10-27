defmodule Naiveticketapp.Payments.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :customer_name, :string
    field :payment_ref, :string
    field :confirmed, :boolean

    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:customer_name, :payment_ref])
    |> validate_required([:customer_name, :payment_ref])
  end
end
