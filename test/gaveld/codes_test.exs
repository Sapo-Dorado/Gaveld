defmodule Gaveld.CodesTest do
  use Gaveld.DataCase

  alias Gaveld.Codes

  describe "words" do
    alias Gaveld.Codes.Word

    @valid_attrs %{word: "some word"}
    @update_attrs %{word: "some updated word"}
    @invalid_attrs %{word: nil}

    def word_fixture(attrs \\ %{}) do
      {:ok, word} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Codes.create_word()

      word
    end

    test "list_words/0 returns all words" do
      word = word_fixture()
      assert Codes.list_words() == [word]
    end

    test "get_word!/1 returns the word with given id" do
      word = word_fixture()
      assert Codes.get_word!(word.id) == word
    end

    test "create_word/1 with valid data creates a word" do
      assert {:ok, %Word{} = word} = Codes.create_word(@valid_attrs)
      assert word.word == "some word"
    end

    test "create_word/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Codes.create_word(@invalid_attrs)
    end

    test "update_word/2 with valid data updates the word" do
      word = word_fixture()
      assert {:ok, %Word{} = word} = Codes.update_word(word, @update_attrs)
      assert word.word == "some updated word"
    end

    test "update_word/2 with invalid data returns error changeset" do
      word = word_fixture()
      assert {:error, %Ecto.Changeset{}} = Codes.update_word(word, @invalid_attrs)
      assert word == Codes.get_word!(word.id)
    end

    test "delete_word/1 deletes the word" do
      word = word_fixture()
      assert {:ok, %Word{}} = Codes.delete_word(word)
      assert_raise Ecto.NoResultsError, fn -> Codes.get_word!(word.id) end
    end

    test "change_word/1 returns a word changeset" do
      word = word_fixture()
      assert %Ecto.Changeset{} = Codes.change_word(word)
    end
  end
end
