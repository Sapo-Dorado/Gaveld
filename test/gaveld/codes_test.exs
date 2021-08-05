defmodule Gaveld.CodesTest do
  use Gaveld.DataCase

  alias Gaveld.Codes

  describe "words" do
    alias Gaveld.Codes.Word

    @noun_attrs %{word: "llama", type: "noun"}
    @adj_attrs %{word: "fancy", type: "adjective"}

    def word_fixture(attrs \\ %{}) do
      {:ok, word} =
        attrs
        |> Enum.into(@noun_attrs)
        |> Codes.create_word()

      word
    end

    test "create_word/1 with valid data creates a word" do
      assert {:ok, %Word{} = word} = Codes.create_word(@noun_attrs)
      assert word.word == @noun_attrs.word
      assert word.type == @noun_attrs.type
    end

    test "create_word/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Codes.create_word(%{})
      assert {:error, %Ecto.Changeset{}} = Codes.create_word(%{word: "word"})
      assert {:error, %Ecto.Changeset{}} = Codes.create_word(%{type: "type"})
    end

    test "get_word/1 returns a word of the desired type" do
      Codes.create_word(@noun_attrs)
      Codes.create_word(@adj_attrs)
      assert %Word{word: "llama"} = Codes.get_word(@noun_attrs.type)
      assert %Word{word: "fancy"}= Codes.get_word(@adj_attrs.type)
    end

    test "gen_code/0 generates a valid code" do
      Codes.create_word(@noun_attrs)
      Codes.create_word(@adj_attrs)
      assert "fancy llama" == Codes.gen_code()
    end
  end
end
