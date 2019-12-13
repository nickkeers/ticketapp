defmodule Naiveticketapp.TicketServer do
  @moduledoc """
  Hold reservations for a number of tickets.

  Acts as a way to serialise requests for a ticket
  """

  use GenServer
  require Logger

  alias Naiveticketapp.Payments
  alias Naiveticketapp.Payments.Ticket

  defmodule State do
    @moduledoc false

    @type t ::  %__MODULE__{
      tickets_available: non_neg_integer() | :loading,
      claims: [{String.t(), DateTime.t()}]
    }
    defstruct [:tickets_available, :claims]
  end

  def start_link(num_tickets \\ 5) do
    GenServer.start_link(__MODULE__, [num_tickets], name: __MODULE__)
  end

  @impl true
  def init([num_tickets]) do
    Logger.debug("Ticket server started, has: #{inspect(num_tickets)} tickets")
    {:ok, %State{tickets_available: :loading}, {:continue, num_tickets}}
  end

  @impl true
  def handle_continue(max_tickets, _state) do
    claims = tickets_to_claims(Payments.list_tickets())
    num_tickets_already_claimed = length(claims)

    tickets_available = get_tickets_available(num_tickets_already_claimed, max_tickets)

    Logger.info("State loaded, number of tickets: #{tickets_available}")

    {:noreply, %State{tickets_available: tickets_available, claims: claims}}
  end

  defp tickets_to_claims(tickets) do
    tickets
    |> Enum.filter(fn ticket -> ticket.confirmed end)
    |> tickets_to_claims([])
  end

  defp tickets_to_claims([], acc), do: acc
  defp tickets_to_claims([%Ticket{customer_name: name, inserted_at: purchased_at} | rest], acc) do
    tickets_to_claims(rest, [{name, purchased_at} | acc])
  end


  # Just a short way of working out the number of tickets, saves a case statement
  # when claimed is >= max, we can return 0 as the result of max - claimed would be 0 as we
  # can't have a negative number of tickets
  defp get_tickets_available(claimed, max) when claimed >= max do
    Logger.warn(
        "number of claimed tickets was greater than or equal to the number of available tickets (#{inspect(claimed)} vs #{inspect(max)})"
      )
    0
  end
  defp get_tickets_available(claimed, max), do: max - claimed

  @impl true
  # block calls whilst we wait to initialise state from the database
  def handle_call(_, _from, %State{tickets_available: :loading} = state) do
    {:reply, {:error, :initialising}, state}
  end

  def handle_call(
        {:claim, name},
        _from,
        %State{} = state
      ) do
    case do_claim(name, state) do
      {:error, _reason} = err ->
        {:reply, err, state}

      {reply, new_state} ->
        {:reply, reply, new_state}
    end
  end

  defp do_claim(name, %State{tickets_available: 0}) do
    Logger.warn("ticket sale failed, tickets sold out", name: inspect(name))
    {:error, :sold_out}
  end

  defp do_claim(name, %State{claims: claims, tickets_available: tickets_left})
       when tickets_left > 0 do
    case has_ticket?(name, claims) do
      false ->
        new_ticket_count = tickets_left - 1
        updated_claims = claims ++ [{name, DateTime.utc_now()}]

        {:ok, %State{claims: updated_claims, tickets_available: new_ticket_count}}

      {:error, :already_claimed} = err ->
        Logger.error("claiming ticket failed, ticket already claimed", name: inspect(name))
        err
    end
  end

  @doc """
  Check if there is a claim for a ticket under the given name
  """
  @spec has_ticket?(String.t(), list({String.t(), DateTime.t()})) ::
          false | {:error, :already_claimed}
  def has_ticket?(name, tickets) do
    case List.keymember?(tickets, name, 1) do
      true ->
        {:error, :already_claimed}

      false ->
        false
    end
  end
end
