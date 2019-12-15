defmodule NaiveticketappWeb.Router do
  use NaiveticketappWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NaiveticketappWeb do
    pipe_through :browser

    resources "/", TicketController, only: [:new, :create, :index, :show]
    resources "/payments", PaymentsController, only: [:new, :create, :show]

    get "/success", WebhooksController, :success
  end

  scope "/hooks", NaiveticketappWeb do
    pipe_through :api

    post "/", WebhooksController, :hooks
  end
end
