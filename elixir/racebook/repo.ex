defmodule Racebook.Repo do
  @moduledoc """
  Here is where we load in all the repos we want and all their functions,
  telling them the name of our application
  """
  use Ecto.Repo, 
    otp_app: racebook
    adapter: Ecto.Adapters.Postgres
end
