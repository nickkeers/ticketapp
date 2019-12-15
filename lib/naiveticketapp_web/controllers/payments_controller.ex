defmodule NaiveticketappWeb.PaymentsController do
  use NaiveticketappWeb, :controller

  alias Naiveticketapp.Checkout
  alias Naiveticketapp.Checkout.Payment
  alias Naiveticketapp.Tickets

  require Logger

  def new(conn, %{"name" => name} = params) do
    Logger.debug("in payments controller! params: #{inspect(params)}")
    changeset = Checkout.change_payment(%Payment{})
    stripe_pkey = Naiveticketapp.get_publishable_stripe_key()

    # todo: save intent id + id + name for verification?
    # setup webhooks for charge.pending to verify ticket sales and then charge.succeeded to get results
    with {:ok, id, intent_id} <- Checkout.create_session() do
      render(conn, "new.html", changeset: changeset, stripe_key: stripe_pkey, checkout_id: id)
    else
      {:error, err = %Stripe.Error{message: stripe_msg}} ->
        Logger.error("payments controller, /new - #{stripe_msg}")
        Logger.error(inspect(err))
        error_msg = "error creating checkout session"

        render(conn, "error.html", error_msg: error_msg)
    end
  end

  def create(conn, %{"payment" => payment_params, "session_id" => session_id}) do
    case Checkout.create_payment(payment_params) do
      {:ok, payment} ->
        conn
        |> put_flash(:info, "accepted payment")
        |> redirect(to: Routes.payments_path(conn, :show, payment))

      {:error, %Ecto.Changeset{} = changeset} ->
        stripe_pkey = Naiveticketapp.get_publishable_stripe_key()
        render(conn, "new.html", changeset: changeset, stripe_key: stripe_pkey)
    end
  end

  def show(conn, %{"id" => id}) do
    payment = Checkout.get_payment!(id)
    render(conn, "show.html", payment: payment)
  end
end
