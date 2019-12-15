defmodule NaiveticketappWeb.PaymentsControllerTest do
  use NaiveticketappWeb.ConnCase

  alias Naiveticketapp.Checkout

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:payments) do
    {:ok, payments} = Checkout.create_payments(@create_attrs)
    payments
  end

  describe "index" do
    test "lists all payments", %{conn: conn} do
      conn = get(conn, Routes.payments_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Payments"
    end
  end

  describe "new payments" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.payments_path(conn, :new))
      assert html_response(conn, 200) =~ "New Payments"
    end
  end

  describe "create payments" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.payments_path(conn, :create), payments: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.payments_path(conn, :show, id)

      conn = get(conn, Routes.payments_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Payments"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.payments_path(conn, :create), payments: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Payments"
    end
  end

  describe "edit payments" do
    setup [:create_payments]

    test "renders form for editing chosen payments", %{conn: conn, payments: payments} do
      conn = get(conn, Routes.payments_path(conn, :edit, payments))
      assert html_response(conn, 200) =~ "Edit Payments"
    end
  end

  describe "update payments" do
    setup [:create_payments]

    test "redirects when data is valid", %{conn: conn, payments: payments} do
      conn = put(conn, Routes.payments_path(conn, :update, payments), payments: @update_attrs)
      assert redirected_to(conn) == Routes.payments_path(conn, :show, payments)

      conn = get(conn, Routes.payments_path(conn, :show, payments))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, payments: payments} do
      conn = put(conn, Routes.payments_path(conn, :update, payments), payments: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Payments"
    end
  end

  describe "delete payments" do
    setup [:create_payments]

    test "deletes chosen payments", %{conn: conn, payments: payments} do
      conn = delete(conn, Routes.payments_path(conn, :delete, payments))
      assert redirected_to(conn) == Routes.payments_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.payments_path(conn, :show, payments))
      end
    end
  end

  defp create_payments(_) do
    payments = fixture(:payments)
    {:ok, payments: payments}
  end
end
