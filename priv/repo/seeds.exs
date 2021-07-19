# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Gaveld.Repo.insert!(%Gaveld.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Gaveld.Codes

{:ok, adjectives} = File.read("priv/repo/words/adjectives.txt")
{:ok, nouns} = File.read("priv/repo/words/nouns.txt")

adjectives
|> String.split("\n", trim: true)
|> Enum.map(fn word -> %{word: word, type: "adjective"} end)
|> Enum.map(&Codes.create_word/1)

nouns
|> String.split("\n", trim: true)
|> Enum.map(fn word -> %{word: word, type: "noun"} end)
|> Enum.map(&Codes.create_word/1)
