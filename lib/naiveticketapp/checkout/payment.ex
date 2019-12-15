defmodule Naiveticketapp.Checkout.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(payments, attrs) do
    payments
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
