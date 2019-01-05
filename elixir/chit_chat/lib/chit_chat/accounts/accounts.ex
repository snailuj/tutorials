defmodule ChitChat.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  # imports only the checkpw/2 and dummy_checkpw/0 functions
  import Comeonin.Argon2, only: [checkpw: 2, dummy_checkpw: 0]

  alias ChitChat.Repo
  # Aliases ChitChat.Accounts.Credential and ChitChat.Accounts.User in one go
  alias ChitChat.Accounts.{Credential, User}

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    Repo.get!(User, id)
    # After getting user we need to preload its credential because most times
    # when you get a User you will also want its email as well
    # We didn't do this in `list_users/0` because when you're listing them all you
    # may not want that information
    # Here, the atom :credential refers to the `belongs_to` field on the %User{}
    # struct defined in user.ex
    |> Repo.preload(:credential)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    # Since User.changeset doesn't create a Credential on its own, we've got to
    # add that in here
    # `cast_assoc` just says it's got an association in it, that will be added to the
    # main User changeset
    # The second param is a keyword list, here we are specifying the function to use when
    # generating the Changeset for making a new Credential
    |> Ecto.Changeset.cast_assoc(:credential, with: &Credential.registration_changeset/2)
    # Repo.insert/1 will insert the User and the Credential
    |> Repo.insert()
  end

  @doc """
  Updates a user and credential. Two paths we want to handle: one is if the user enters
  their password and they want to change their password, the other is if they don't want
  to change their password, in which case it will be annoying to have to type it in twice.

  For the first case, we'll use `Credential.registration_changeset/2`, for the other case
  we'll use `Credential.changeset/2`.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    # Figure out which changeset we want to use
    # if there's a credential inside the attrs and it has a password and it's empty string
    cred_changeset =
      if attrs["credential"]["password"] == "" do
        &Credential.changeset/2
      else
        &Credential.registration_changeset/2
      end

    user
    |> User.changeset(attrs)
    # If there's no credential at all in the attrs, then Ecto won't do anything to it when we
    # `cast_assoc` so even though it's technically being given the `registration_changeset`
    # function, it won't do anything anyway so it doesn't matter
    |> Ecto.Changeset.cast_assoc(:credential, with: cred_changeset)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  alias ChitChat.Accounts.Credential

  def authenticate_by_email_password(email, given_pass) do
    cred =
      Repo.get_by(Credential, email: email)
      |> Repo.preload(:user)

    cond do
      cred && checkpw(given_pass, cred.password_hash) ->
        {:ok, cred.user}

      # password didn't match the email
      cred ->
        {:error, :unauthorized}

      # email doesn't exist in db
      true ->
        dummy_checkpw()
        {:error, :not_found}
    end
  end

  #
  ## Credentials are never accessed or updated outside of a User,
  # so commenting these functions out
  #

  #   @doc """
  #   Returns the list of credentials.

  #   ## Examples

  #       iex> list_credentials()
  #       [%Credential{}, ...]

  #   """
  #   def list_credentials do
  #     Repo.all(Credential)
  #   end

  #   @doc """
  #   Gets a single credential.

  #   Raises `Ecto.NoResultsError` if the Credential does not exist.

  #   ## Examples

  #       iex> get_credential!(123)
  #       %Credential{}

  #       iex> get_credential!(456)
  #       ** (Ecto.NoResultsError)

  #   """
  #   def get_credential!(id), do: Repo.get!(Credential, id)

  #   @doc """
  #   Creates a credential.

  #   ## Examples

  #       iex> create_credential(%{field: value})
  #       {:ok, %Credential{}}

  #       iex> create_credential(%{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """
  #   def create_credential(attrs \\ %{}) do
  #     %Credential{}
  #     |> Credential.changeset(attrs)
  #     |> Repo.insert()
  #   end

  #   @doc """
  #   Updates a credential.

  #   ## Examples

  #       iex> update_credential(credential, %{field: new_value})
  #       {:ok, %Credential{}}

  #       iex> update_credential(credential, %{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """
  #   def update_credential(%Credential{} = credential, attrs) do
  #     credential
  #     |> Credential.changeset(attrs)
  #     |> Repo.update()
  #   end

  #   @doc """
  #   Deletes a Credential.

  #   ## Examples

  #       iex> delete_credential(credential)
  #       {:ok, %Credential{}}

  #       iex> delete_credential(credential)
  #       {:error, %Ecto.Changeset{}}

  #   """
  #   def delete_credential(%Credential{} = credential) do
  #     Repo.delete(credential)
  #   end

  #   @doc """
  #   Returns an `%Ecto.Changeset{}` for tracking credential changes.

  #   ## Examples

  #       iex> change_credential(credential)
  #       %Ecto.Changeset{source: %Credential{}}

  #   """
  #   def change_credential(%Credential{} = credential) do
  #     Credential.changeset(credential, %{})
  #   end
end
