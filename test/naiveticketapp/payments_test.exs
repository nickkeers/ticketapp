defmodule Naiveticketapp.PaymentsTest do
  use Naiveticketapp.DataCase

  alias Naiveticketapp.Payments

  describe "tickets" do
    alias Naiveticketapp.Payments.Ticket

    @valid_attrs %{customer_name: "some customer_name", payment_ref: "some payment_ref"}
    @update_attrs %{
      customer_name: "some updated customer_name",
      payment_ref: "some updated payment_ref"
    }
    @invalid_attrs %{customer_name: nil, payment_ref: nil}

    def ticket_fixture(attrs \\ %{}) do
      {:ok, ticket} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Payments.create_ticket()

      ticket
    end

    test "list_tickets/0 returns all tickets" do
      ticket = ticket_fixture()
      assert Payments.list_tickets() == [ticket]
    end

    test "get_ticket!/1 returns the ticket with given id" do
      ticket = ticket_fixture()
      assert Payments.get_ticket!(ticket.id) == ticket
    end

    test "create_ticket/1 with valid data creates a ticket" do
      assert {:ok, %Ticket{} = ticket} = Payments.create_ticket(@valid_attrs)
      assert ticket.customer_name == "some customer_name"
      assert ticket.payment_ref == "some payment_ref"
    end

    test "create_ticket/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_ticket(@invalid_attrs)
    end

    test "update_ticket/2 with valid data updates the ticket" do
      ticket = ticket_fixture()
      assert {:ok, %Ticket{} = ticket} = Payments.update_ticket(ticket, @update_attrs)
      assert ticket.customer_name == "some updated customer_name"
      assert ticket.payment_ref == "some updated payment_ref"
    end

    test "update_ticket/2 with invalid data returns error changeset" do
      ticket = ticket_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_ticket(ticket, @invalid_attrs)
      assert ticket == Payments.get_ticket!(ticket.id)
    end

    test "delete_ticket/1 deletes the ticket" do
      ticket = ticket_fixture()
      assert {:ok, %Ticket{}} = Payments.delete_ticket(ticket)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_ticket!(ticket.id) end
    end

    test "change_ticket/1 returns a ticket changeset" do
      ticket = ticket_fixture()
      assert %Ecto.Changeset{} = Payments.change_ticket(ticket)
    end
  end
end
