defmodule Naiveticketapp.TicketsTest do
  use Naiveticketapp.DataCase

  alias Naiveticketapp.Tickets

  describe "tickets" do
    alias Naiveticketapp.Tickets.Ticket

    @valid_attrs %{
      customer_name: "some customer_name",
      payment_ref: "some payment_ref",
      confirmed: false
    }
    @update_attrs %{
      customer_name: "some updated customer_name",
      payment_ref: "some updated payment_ref",
      confirmed: true
    }
    @invalid_attrs %{customer_name: nil, payment_ref: nil, confirmed: nil}

    def ticket_fixture(attrs \\ %{}) do
      {:ok, ticket} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tickets.create_ticket()

      ticket
    end

    test "list_tickets/0 returns all tickets" do
      ticket = ticket_fixture()
      assert Tickets.list_tickets() == [ticket]
    end

    test "get_ticket!/1 returns the ticket with given id" do
      ticket = ticket_fixture()
      assert Tickets.get_ticket!(ticket.id) == ticket
    end

    test "create_ticket/1 with valid data creates a ticket" do
      assert {:ok, %Ticket{} = ticket} = Tickets.create_ticket(@valid_attrs)
      assert ticket.customer_name == "some customer_name"
      assert ticket.payment_ref == "some payment_ref"
    end

    test "create_ticket/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tickets.create_ticket(@invalid_attrs)
    end

    test "update_ticket/2 with valid data updates the ticket" do
      ticket = ticket_fixture()
      assert {:ok, %Ticket{} = ticket} = Tickets.update_ticket(ticket, @update_attrs)
      assert ticket.customer_name == "some updated customer_name"
      assert ticket.payment_ref == "some updated payment_ref"
    end

    test "update_ticket/2 with invalid data returns error changeset" do
      ticket = ticket_fixture()
      assert {:error, %Ecto.Changeset{}} = Tickets.update_ticket(ticket, @invalid_attrs)
      assert ticket == Tickets.get_ticket!(ticket.id)
    end

    test "delete_ticket/1 deletes the ticket" do
      ticket = ticket_fixture()
      assert {:ok, %Ticket{}} = Tickets.delete_ticket(ticket)
      assert_raise Ecto.NoResultsError, fn -> Tickets.get_ticket!(ticket.id) end
    end

    test "change_ticket/1 returns a ticket changeset" do
      ticket = ticket_fixture()
      assert %Ecto.Changeset{} = Tickets.change_ticket(ticket)
    end
  end
end
