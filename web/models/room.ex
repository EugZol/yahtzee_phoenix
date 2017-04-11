defmodule YahtzeePhoenix.Room do
  use YahtzeePhoenix.Web, :model

  @token_length 8

  @derive {Phoenix.Param, key: :token}

  schema "rooms" do
    field :token, :string
    field :winner_id, :integer

    timestamps()
  end

  def create do
    %__MODULE__{}
    |> cast(%{}, [:token, :winner_id])
    |> generate_token
  end

  defp generate_token(changeset) do
    token = :crypto.strong_rand_bytes(@token_length) |> Base.url_encode64 |> binary_part(0, @token_length)
    put_change changeset, :token, token
  end
end
