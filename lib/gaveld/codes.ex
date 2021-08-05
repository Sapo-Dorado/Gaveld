defmodule Gaveld.Codes do

  import Ecto.Query, warn: false
  alias Gaveld.Repo

  alias Gaveld.Codes.Word


  def create_word(attrs) do
    %Word{}
    |> Word.changeset(attrs)
    |> Repo.insert()
  end

  def get_word(type) do
    query  =
      from w in Word,
      where: w.type == ^type,
      order_by: fragment("RANDOM()"),
      limit: 1

    Repo.all(query)
    |> List.first
  end

  def gen_code() do
    adjective = get_word("adjective").word
    noun = get_word("noun").word
    adjective <> " " <> noun
  end

end
