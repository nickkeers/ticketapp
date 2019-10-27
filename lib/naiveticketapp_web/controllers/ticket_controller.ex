defmodule NaiveticketappWeb.TicketController do
  use NaiveticketappWeb, :controller

  alias Naiveticketapp.Payments
  alias Naiveticketapp.Payments.Ticket

  def index(conn, _params) do
    conn
    |> redirect(to: Routes.ticket_path(conn, :new))
  end

  def new(conn, _params) do
    changeset = Payments.change_ticket(%Ticket{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"ticket" => ticket_params}) do
    case Payments.create_ticket(ticket_params) do
      {:ok, ticket} ->
        conn
        |> put_flash(:info, "Ticket created successfully.")
        |> redirect(to: Routes.ticket_path(conn, :show, ticket))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    ticket = Payments.get_ticket!(id)
    render(conn, "show.html", ticket: ticket)
  end
end
