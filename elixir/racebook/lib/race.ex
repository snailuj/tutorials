defmodule Racebook.Race do
  use Ecto.Schema

  schema "races" do
    field :name, :string
    field :rating, :integer, default: 6
    timestamps
  end
end
