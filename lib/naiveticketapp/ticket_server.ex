defmodule Naiveticketapp.TicketServer do
  @moduledoc """
  Hold reservations for a number of tickets.

  Acts as a way to serialise requests for a ticket
  """

  use GenServer
  require Logger

  alias Naiveticketapp.Tickets
  alias Naiveticketapp.Tickets.Ticket

  defmodule State do
    @moduledoc false

    @type t :: %__MODULE__{
            tickets_available: non_neg_integer() | :loading,
            claims: [{String.t(), DateTime.t()}],
            poll_timer: reference(),
            max_tickets: non_neg_integer()
          }
    defstruct [:tickets_available, :claims, :poll_timer, :max_tickets]
  end

  def start_link(num_tickets \\ 5) do
    GenServer.start_link(__MODULE__, [num_tickets], name: __MODULE__)
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

  @doc """
  Get the number of remaining tickets
  """
  @spec get_ticket_count() :: non_neg_integer() | {:error, :initialising}
  def get_ticket_count() do
    GenServer.call(__MODULE__, :get_ticket_count)
  end

  # ----------

  @impl true
  def init([num_tickets]) do
    Logger.debug("Ticket server started, has: #{inspect(num_tickets)} tickets")
    {:ok, %State{tickets_available: :loading}, {:continue, num_tickets}}
  end

  @impl true
  def handle_continue(max_tickets, _state) do
    {tickets_available, claims} = fetch_tickets_and_claims(max_tickets)

    poll_timer = Process.send_after(self(), :poll, 15_000)

    {:noreply,
     %State{
       max_tickets: max_tickets,
       tickets_available: tickets_available,
       claims: claims,
       poll_timer: poll_timer
     }}
  end

  @impl true
  def handle_info(:poll, %State{poll_timer: timer, max_tickets: max_tickets} = state) do
    Logger.debug("Polling for the available number of tickets")
    Process.cancel_timer(timer)
    {tickets_available, claims} = fetch_tickets_and_claims(max_tickets)
    new_poll_timer = Process.send_after(self(), :poll, 15_000)

    {:noreply,
     %{state | claims: claims, tickets_available: tickets_available, poll_timer: new_poll_timer}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  @impl true
  # block calls whilst we wait to initialise state from the database
  def handle_call(_, _from, %State{tickets_available: :loading} = state) do
    {:reply, {:error, :initialising}, state}
  end

  def handle_call(:get_ticket_count, _from, %State{tickets_available: tickets} = state) do
    {:reply, tickets, state}
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

  # --------

  defp fetch_tickets_and_claims(max_tickets) do
    claims = tickets_to_claims(Tickets.list_tickets())
    num_tickets_already_claimed = length(claims)

    tickets_available = get_available_tickets(num_tickets_already_claimed, max_tickets)
    {tickets_available, claims}
  end

  # Convert the list of %Ticket{}'s into a KV list of {name, purchase date}
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
  defp get_available_tickets(claimed, max) when claimed >= max do
    Logger.warn(
      "number of claimed tickets was greater than or equal to the number of available tickets (#{
        inspect(claimed)
      } vs #{inspect(max)})"
    )

    0
  end

  defp get_available_tickets(claimed, max), do: max - claimed
end
