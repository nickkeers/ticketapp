defmodule Naiveticketapp.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Naiveticketapp.Repo,
      NaiveticketappWeb.Endpoint,
      {Naiveticketapp.TicketServer, 5}
    ]

    opts = [strategy: :one_for_one, name: Naiveticketapp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    NaiveticketappWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
