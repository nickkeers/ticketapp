defmodule Naiveticketapp.CheckoutTest do
  use Naiveticketapp.DataCase

  alias Naiveticketapp.Checkout

  describe "payments" do
    alias Naiveticketapp.Checkout.Payments

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def payments_fixture(attrs \\ %{}) do
      {:ok, payments} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Checkout.create_payments()

      payments
    end

    test "list_payments/0 returns all payments" do
      payments = payments_fixture()
      assert Checkout.list_payments() == [payments]
    end

    test "get_payments!/1 returns the payments with given id" do
      payments = payments_fixture()
      assert Checkout.get_payments!(payments.id) == payments
    end

    test "create_payments/1 with valid data creates a payments" do
      assert {:ok, %Payments{} = payments} = Checkout.create_payments(@valid_attrs)
      assert payments.name == "some name"
    end

    test "create_payments/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Checkout.create_payments(@invalid_attrs)
    end

    test "update_payments/2 with valid data updates the payments" do
      payments = payments_fixture()
      assert {:ok, %Payments{} = payments} = Checkout.update_payments(payments, @update_attrs)
      assert payments.name == "some updated name"
    end

    test "update_payments/2 with invalid data returns error changeset" do
      payments = payments_fixture()
      assert {:error, %Ecto.Changeset{}} = Checkout.update_payments(payments, @invalid_attrs)
      assert payments == Checkout.get_payments!(payments.id)
    end

    test "delete_payments/1 deletes the payments" do
      payments = payments_fixture()
      assert {:ok, %Payments{}} = Checkout.delete_payments(payments)
      assert_raise Ecto.NoResultsError, fn -> Checkout.get_payments!(payments.id) end
    end

    test "change_payments/1 returns a payments changeset" do
      payments = payments_fixture()
      assert %Ecto.Changeset{} = Checkout.change_payments(payments)
    end
  end
end
