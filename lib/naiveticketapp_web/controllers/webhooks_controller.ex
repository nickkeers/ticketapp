defmodule NaiveticketappWeb.WebhooksController do
  use NaiveticketappWeb, :controller

  require Logger

  def success(conn, %{"session_id" => _session_id} = params) do
    render(conn, "success.html", data: inspect(params))
  end

  def hooks(conn, params) do
    signature = Plug.Conn.get_req_header(conn, "Stripe-Signature")
    body = conn.assigns[:raw_body]

    case Stripe.Webhook.construct_event(
           body,
           signature,
           "whsec_UwphMBQCOt6wmKHwNgtGtRiVmqSljdY8",
           300
         ) do
      {:ok, event} ->
        Logger.debug("stripe webhook: #{inspect(event)}")
        render(conn, %{})

      {:error, err} ->
        Logger.error("stripe webhook error! #{inspect(err)}")

        conn
        |> Plug.Conn.put_status(400)
        |> render(%{})
    end
  end
end
