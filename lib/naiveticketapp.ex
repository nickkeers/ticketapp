defmodule Naiveticketapp do
  def get_publishable_stripe_key() do
    Application.get_env(:naiveticketapp, :stripe_publishable_key)
  end

  @doc """
  Get the configured base url and append '/suffix to it'

  ## Examples

    iex> Naiveticketapp.get_public_url("success")
    "https://localhost:4000/success"

  """
  def get_public_url(suffix) do
    Application.get_env(:naiveticketapp, :base_url)
    |> URI.merge(suffix)
    |> URI.to_string()
  end
end
