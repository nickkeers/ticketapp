defmodule NaiveticketappWeb.TicketController do
  use NaiveticketappWeb, :controller

  alias Naiveticketapp.Tickets
  alias Naiveticketapp.Tickets.Ticket
  alias Naiveticketapp.TicketServer
  alias Naiveticketapp.Reservations

  require Logger

  def index(conn, _params) do
    conn
    |> redirect(to: Routes.ticket_path(conn, :new))
  end

  def new(conn, _params) do
    changeset = Tickets.change_ticket(%Ticket{})
    ticket_count = TicketServer.get_ticket_count()
    render(conn, "new.html", changeset: changeset, ticket_count: ticket_count)
  end

  def create(conn, %{"ticket" => ticket_params}) do
    with {:ok, ticket} <- Tickets.create_ticket(ticket_params),
         {:ok, reservation_id} <- TicketServer.reserve_ticket(ticket) do
      conn
      |> put_flash(:info, "Ticket reserved!")
      |> redirect(to: Routes.payments_path(conn, :new, reservation: URI.encode(reservation_id)))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        ticket_count = TicketServer.get_ticket_count()
        Logger.error("Error reserving ticket! Changeset: #{inspect(changeset)}")
        render(conn, "new.html", changeset: changeset, ticket_count: ticket_count)
    end
  end

  def show(conn, %{"id" => id}) do
    ticket = Tickets.get_ticket!(id)
    render(conn, "show.html", ticket: ticket)
  end
end
