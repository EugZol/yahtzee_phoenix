defmodule YahtzeePhoenix.Room do
  use YahtzeePhoenix.Web, :model

  @token_length 8

  @derive {Phoenix.Param, key: :token}

  schema "rooms" do
    field :token, :string
    field :state, :map

    belongs_to :winner, YahtzeePhoenix.User

    timestamps()
  end

  def create_changeset do
    %__MODULE__{}
    |> cast(%{}, [:token])
    |> generate_token
  end

  def game_over_changeset(room, winner_id, state) do
    room
    |> cast(%{winner_id: winner_id, state: state}, [:winner_id, :state])
  end

  def with_winner(query) do
    from r in query,
      preload: :winner
  end

  def open(query) do
    from r in query,
      where: is_nil(r.winner_id)
  end

  def finished(query) do
    from r in query,
      where: not(is_nil(r.winner_id))
  end

  defp generate_token(changeset) do
    token = :crypto.strong_rand_bytes(@token_length) |> Base.url_encode64 |> binary_part(0, @token_length)
    put_change changeset, :token, token
  end
end
