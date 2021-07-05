defmodule Gaveld.Codes.Word do
  use Ecto.Schema
  import Ecto.Changeset

  schema "words" do
    field :word, :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:word, :type])
    |> validate_required([:word, :type])
    |> unique_constraint(:word)
  end
end
