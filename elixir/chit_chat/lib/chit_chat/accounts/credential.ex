defmodule ChitChat.Accounts.Credential do
  use Ecto.Schema
  import Ecto.Changeset
  alias Comeonin.Argon2

  schema "credentials" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    belongs_to :user, ChitChat.Accounts.User

    timestamps()
  end

  @doc """
  Called when user doesn't supply a password confirmation
  (we assume it's just a profile update, not a registration)

  Changesets are called on form submission.
  """
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:email])
    |> validate_required([:email])
    # Obviously would want better validation here
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  @spec registration_changeset(any(), any()) :: none()
  def registration_changeset(struct, attrs = %{}) do
    struct
    # first of all, run it through the function above to do all that and then additionally do this
    |> changeset(attrs)
    # cast/4 applies changes to `struct` for all params whose keys are in the list
    |> cast(attrs, [:password, :password_confirmation])
    # if one of these validations fails, it will still pass on the changeset, but its :valid field will == false
    # and it will have an errors array as well
    |> validate_required(attrs, [:password, :password_confirmation])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> hash_password()
  end

  @spec hash_password(%{valid?: boolean(), changes: %{password: String.t}}) :: %{valid?: boolean()}
  def hash_password(%{valid?: true, changes: %{password: pass}} = changeset) do
    put_change(changeset, :password_hash, Argon2.hashpwsalt(pass))
  end

  #when changeset has valid=false set on it, then don't update :password_hash, just pass it along with the errors array
  def hash_password(%{valid?: false} = changeset), do: changeset
end
