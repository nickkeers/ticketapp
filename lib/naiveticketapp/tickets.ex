defmodule Naiveticketapp.Tickets do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Naiveticketapp.Repo

  alias Naiveticketapp.Tickets.Ticket

  @doc """
  Returns the list of tickets.

  ## Examples

      iex> list_tickets()
      [%Ticket{}, ...]

  """
  def list_tickets do
    Repo.all(Ticket)
  end

  def get_reservations do
    from(t in Ticket, where: t.reserved == true)
    |> Repo.all()
  end

  def set_payment_intent_for_customer(name, intent_id) do
    from(t in Ticket, where: t.name == ^name)
    |> Repo.one()
    |> Ticket.changeset(%{intent_id: intent_id})
    |> Repo.update()
  end

  @doc """
  Return a list of tickets which are confirmed (purchased)
  """
  def get_confirmed_tickets do
    from(t in Ticket, where: t.confirmed == true)
    |> Repo.all()
  end

  @doc """
  Return the number of tickets claimed (number of rows in the ticket table)
  """
  @spec get_num_claimed() :: integer()
  def get_num_claimed do
    length(get_confirmed_tickets())
  end

  @doc """
  Gets a single ticket.

  Raises `Ecto.NoResultsError` if the Ticket does not exist.

  ## Examples

      iex> get_ticket!(123)
      %Ticket{}

      iex> get_ticket!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ticket!(id), do: Repo.get!(Ticket, id)

  @doc """
  Creates a ticket.

  ## Examples

      iex> create_ticket(%{field: value})
      {:ok, %Ticket{}}

      iex> create_ticket(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ticket(attrs \\ %{}) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ticket.

  ## Examples

      iex> update_ticket(ticket, %{field: new_value})
      {:ok, %Ticket{}}

      iex> update_ticket(ticket, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Ticket.

  ## Examples

      iex> delete_ticket(ticket)
      {:ok, %Ticket{}}

      iex> delete_ticket(ticket)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ticket changes.

  ## Examples

      iex> change_ticket(ticket)
      %Ecto.Changeset{source: %Ticket{}}

  """
  def change_ticket(%Ticket{} = ticket) do
    Ticket.changeset(ticket, %{})
  end
end
