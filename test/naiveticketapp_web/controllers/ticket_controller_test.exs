defmodule NaiveticketappWeb.TicketControllerTest do
  use NaiveticketappWeb.ConnCase

  alias Naiveticketapp.Tickets

  @create_attrs %{
    customer_name: "some customer_name",
    payment_ref: "some payment_ref",
    confirmed: false
  }
  @invalid_attrs %{customer_name: nil, payment_ref: nil}

  def fixture(:ticket) do
    {:ok, ticket} = Tickets.create_ticket(@create_attrs)
    ticket
  end

  describe "index" do
    test "index redirects to new ticket page", %{conn: conn} do
      conn = get(conn, Routes.ticket_path(conn, :index))
      assert redirected_to(conn, 302) =~ "/new"
    end
  end

  describe "new ticket" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.ticket_path(conn, :new))
      assert html_response(conn, 200) =~ "Buy your ticket"
    end
  end

  describe "create ticket" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.ticket_path(conn, :create), ticket: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.ticket_path(conn, :show, id)

      conn = get(conn, Routes.ticket_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Ticket"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.ticket_path(conn, :create), ticket: @invalid_attrs)
      assert html_response(conn, 200) =~ "Buy your ticket"
    end
  end
end
