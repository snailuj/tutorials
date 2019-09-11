defmodule Rumbl.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def registration_changeset(user, params) do
    user
    # get a changeset for the non-sensitive stuff
    |> changeset(params)
    # add password
    |> cast(params, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 128)
    |> validate_format(:password, ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])/,
      # TODO gettext me
      message: "must contain at least one number, one lowercase and one uppercase letter"
    )
    |> put_password_hash()
  end

  @doc """
    Used for update non-sensitive user info
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username])
    |> validate_required([:name, :username])
    |> validate_length(:username, min: 1, max: 20)
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(password))

      # don't transform the changeset if invalid or password not changed
      _ ->
        changeset
    end
  end
end
