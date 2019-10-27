defmodule NaiveticketappWeb.PageController do
  use NaiveticketappWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
