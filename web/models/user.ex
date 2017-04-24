defmodule YahtzeePhoenix.User do
  use YahtzeePhoenix.Web, :model

  alias YahtzeePhoenix.Repo
  alias YahtzeePhoenix.User
  alias YahtzeePhoenix.Room

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> unique_constraint(:email)
    |> hash_password
  end

  @doc """
  Returns user if email and password match
  """
  def login(%{"email" => email, "password" => password}) do
    user = Repo.get_by(User, email: email)
    if user && Hasher.check_password_hash(password, user.password_hash) do
      {:ok, user}
    else
      :error
    end
  end

  def score(user) do
    from r in Room,
      where: r.winner_id == ^user.id,
      select: count(r.id)
  end

  defp hash_password(changeset) do
    if changeset.params["password"] do
      changeset
      |> put_change(:password_hash, Hasher.salted_password_hash(changeset.params["password"]))
    else
      changeset
    end
  end
end
