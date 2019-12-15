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
            max_tickets: non_neg_integer(),
            reservations: [{String.t(), %Ticket{}, DateTime.t()}]
          }
    defstruct [:tickets_available, :claims, :poll_timer, :max_tickets, :reservations]
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

  @doc """
  Create a reservation process for a ticket, by default keeps the reservation for
  3 mins which should be long enough to complete the checkout flow

  # Arguments
  * ticket - `Naiveticketapp.Ticket` holds info about a ticket, at first, just the
  customer name
  * time - Time in milliseconds for the reservation duration

  Returns `{:ok, reservation_id}` when successful, and `{:error, any()}` when
  unsuccessful
  """
  @spec reserve_ticket(%Ticket{}) :: {:ok, binary()} | {:error, any()}
  def reserve_ticket(%Ticket{} = ticket, time \\ 180_000) do
    GenServer.call(__MODULE__, {:reserve_ticket, ticket, time})
  end

  @spec get_reservation(binary()) ::
          {:ok, {binary(), %Ticket{}, DateTime.t()}} | {:error, :no_reservation}
  def get_reservation(id) do
    GenServer.call(__MODULE__, {:get_reservation, id})
  end

  def has_reservation?(id) do
    GenServer.call(__MODULE__, {:has_reservation, id})
  end

  def set_intent_id(reservation, intent_id) do
    GenServer.cast(__MODULE__, {:set_intent_id, reservation, intent_id})
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
    reservations = Tickets.get_reservations() |> convert_reservations()

    poll_timer = Process.send_after(self(), :poll, 15_000)

    {:noreply,
     %State{
       max_tickets: max_tickets,
       tickets_available: tickets_available,
       claims: claims,
       poll_timer: poll_timer,
       reservations: reservations
     }}
  end

  @impl true
  def handle_info(
        :poll,
        %State{poll_timer: timer, max_tickets: max_tickets, reservations: reservations} = state
      ) do
    Logger.debug("Polling for the available number of tickets")
    Process.cancel_timer(timer)
    {tickets_available, claims} = fetch_tickets_and_claims(max_tickets)

    Logger.debug("Checking reservations for expirations")
    {expired, not_expired} = filter_expired_reservations(reservations)

    :ok = unreserve_tickets(expired)

    # TODO: send to channel that reservations are expired?

    new_poll_timer = Process.send_after(self(), :poll, 15_000)

    {:noreply,
     %{
       state
       | claims: claims,
         reservations: not_expired,
         tickets_available: tickets_available,
         poll_timer: new_poll_timer
     }}
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

  def handle_call(_, _from, %State{tickets_available: 0} = state) do
    {:reply, {:error, :no_tickets}, state}
  end

  def handle_call({:get_reservation, id}, _from, %State{reservations: reservations} = state) do
    reply = get_reservation(id, reservations)

    {:reply, reply, state}
  end

  def handle_call({:has_reservation, id}, _from, %State{reservations: reservations} = state) do
    Logger.debug("check reservation for '#{inspect(id)}' in #{inspect(reservations)}")

    has_reservation =
      case get_reservation(id, reservations) do
        {:error, :no_reservation} -> false
        _ -> true
      end

    {:reply, has_reservation, state}
  end

  def handle_call(
        {:reserve_ticket, %Ticket{} = ticket, time},
        _from,
        %State{claims: claims, reservations: reservations} = state
      ) do
    # if the customer doesn't have a ticket, we can reserve one
    if not has_ticket?(ticket.customer_name, claims) do
      # if the customer has no ticket, and no reservation, we can create one
      # else, we can return it
      # we have a subtle bug here - if the reservation has expired, but the polling
      # hasn't picked it up yet, then we would return the id, so get_reservation_id needs
      # to check expiry too
      case get_reservation_id(ticket.customer_name, reservations) do
        {:ok, id} ->
          {:reply, {:ok, id}, state}

        _ ->
          {id, ^ticket, expiry} =
            entry =
            generate_reservation_id()
            |> create_reservation_entry(ticket, time)

          Logger.debug("reserve_ticket - entry: #{inspect(entry)}")

          {:ok, ticket} =
            Tickets.update_ticket(ticket, %{
              reserved: true,
              reserved_until: expiry,
              reservation_id: id
            })

          new_reservations = merge_reservations({id, ticket, expiry}, reservations)

          {:reply, {:ok, id}, %{state | reservations: new_reservations}}
      end
    else
      {:reply, {:error, :has_ticket}, state}
    end
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

  @impl true
  def handle_cast(
        {:set_intent_id, reservation, intent_id},
        %State{reservations: reservations} = state
      ) do
    case get_reservation(reservation, reservations) do
      {:ok, {^reservation, ticket, _}} ->
        Tickets.update_ticket(ticket, %{intent_id: intent_id})

      _ ->
        Logger.debug(
          "tried to set intent id for reservation #{inspect(reservation)} but there was no such reservation"
        )

        nil
    end

    {:noreply, state}
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

    tickets_available =
      length(claims)
      |> get_available_tickets(max_tickets)

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

  defp create_reservation_entry(id, %Ticket{} = ticket, time) do
    expiry =
      DateTime.utc_now()
      |> DateTime.add(time, :millisecond)

    {id, ticket, expiry}
  end

  defp generate_reservation_id() do
    Ecto.UUID.generate()
  end

  defp get_reservation_id(name, reservations) do
    now = DateTime.utc_now()

    case Enum.filter(reservations, fn
           {_id, %Ticket{customer_name: ^name}, expiry} ->
             DateTime.compare(now, expiry) == :gt

           {_, _, _} ->
             false
         end) do
      [{id, %Ticket{}, _}] -> {:ok, id}
      _ -> {:error, :no_reservation}
    end
  end

  def merge_reservations({id, ticket, expiry} = entry, reservations) do
    case List.keyfind(reservations, id, 0) do
      {^id, _ticket, _expiry} ->
        List.keyreplace(reservations, id, 1, {id, ticket, expiry})

      _ ->
        [entry | reservations]
    end
  end

  def get_reservation(id, reservations) do
    case List.keyfind(reservations, id, 0) do
      {^id, _ticket, _} = entry ->
        {:ok, entry}

      _ ->
        {:error, :no_reservation}
    end
  end

  # returns a tuple of {expired, not expired} reservations
  defp filter_expired_reservations(reservations) do
    now = DateTime.utc_now()

    Enum.split_with(reservations, fn {_id, _ticket, expiry} ->
      DateTime.compare(now, expiry) == :gt
    end)
  end

  defp unreserve_tickets(tickets) do
    for {_, ticket, _} <- tickets do
      Tickets.update_ticket(ticket, %{reserved: false, reserved_until: nil})
    end

    :ok
  end

  defp convert_reservations(reservations) do
    for ticket <- reservations do
      {ticket.reservation_id, ticket, ticket.reserved_until}
    end
  end
end
