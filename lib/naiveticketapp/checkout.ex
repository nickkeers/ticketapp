defmodule Naiveticketapp.Checkout do
  @moduledoc """
  The Checkout context.
  """

  import Ecto.Query, warn: false
  alias Naiveticketapp.Repo
  alias Naiveticketapp.TicketServer
  alias Naiveticketapp.Checkout.Payment

  def create_session() do
    result =
      Stripe.Session.create(%{
        payment_method_types: ["card"],
        line_items: [
          %{
            amount: 500,
            currency: "gbp",
            quantity: 1,
            name: "Event Ticket",
            description: "A pre-release ticket for our latest event"
          }
        ],
        success_url: Naiveticketapp.get_public_url("/success?session_id={CHECKOUT_SESSION_ID}"),
        cancel_url: Naiveticketapp.get_public_url("/new")
      })

    case result do
      {:ok, %Stripe.Session{id: session_id, payment_intent: intent_id}} ->
        {:ok, session_id, intent_id}

      {:error, %Stripe.Error{}} = err ->
        err
    end
  end

  @doc """
  Returns the list of payments.

  ## Examples

      iex> list_payment()
      [%Payment{}, ...]

  """
  def list_payment do
    Repo.all(Payment)
  end

  @doc """
  Gets a single Payment.

  Raises `Ecto.NoResultsError` if the Payment does not exist.

  ## Examples

      iex> get_payment!(123)
      %Payment{}

      iex> get_payment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_payment!(id), do: Repo.get!(Payment, id)

  @doc """
  Creates a Payment.

  ## Examples

      iex> create_payment(%{field: value})
      {:ok, %Payment{}}

      iex> create_payment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment(attrs \\ %{}) do
    %Payment{}
    |> Payment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a Payment.

  ## Examples

      iex> update_Payment(Payment, %{field: new_value})
      {:ok, %Payment{}}

      iex> update_Payment(Payment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payment(%Payment{} = payment, attrs) do
    payment
    |> Payment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Payment.

  ## Examples

      iex> delete_payment(Payment)
      {:ok, %Payment{}}

      iex> delete_payment(Payment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_payment(%Payment{} = payment) do
    Repo.delete(payment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking Payment changes.

  ## Examples

      iex> change_payment(Payment)
      %Ecto.Changeset{source: %Payment{}}

  """
  def change_payment(%Payment{} = payment) do
    Payment.changeset(payment, %{})
  end
end
