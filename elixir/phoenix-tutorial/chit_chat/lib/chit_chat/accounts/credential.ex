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

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  #register new account or change password
  def registration_changeset(struct, attrs \\ %{}) do #double-backslash gives you a default parameter
    #if any of these validations fail, it will still return and continue on with the pipeline, but will set :valid to false
    struct
    |> changeset(attrs) #do everything the changeset() does, then do extra checks
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password) #validates that two attrs are the same, assumes the confirmation attr is named *_confirmation
    |> hash_password()
  end

  #if invalid, just pass it along and let the invalid property propagate to global error handling
  def hash_password(%{valid?: false} = changeset), do: changeset

  #if valid, then put a change as the encrypted password into the changeset at key :password_hash
  def hash_password(%{valid?: true, changes: %{password: pass}} = changeset) do
    put_change(changeset, :password_hash, Argon2.hashpwsalt(pass))
  end
end
