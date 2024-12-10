defmodule Mnemonist.Wordlist do
  @moduledoc false

  @word_to_index Mnemonist.__supported_languages()
                 |> Map.new(fn language ->
                   words =
                     :mnemonist
                     |> :code.priv_dir()
                     |> Path.join("/words/#{language}.txt")
                     |> File.stream!()
                     |> Stream.map(&String.trim/1)
                     |> Stream.with_index()
                     |> Map.new()

                   {to_string(language), words}
                 end)

  @index_to_word Map.new(@word_to_index, fn {language, word_to_index} ->
                   {language, Map.new(word_to_index, fn {k, v} -> {v, k} end)}
                 end)

  def fetch_word(language, index) do
    case index_to_word(language) do
      {:ok, wordlist} ->
        case Map.fetch(wordlist, index) do
          :error -> {:error, invalid_index(index, language)}
          {:ok, word} -> {:ok, word}
        end

      error ->
        error
    end
  end

  def fetch_word!(language, index) do
    case fetch_word(language, index) do
      {:ok, word} -> word
      {:error, reason} -> raise MnemonistError, reason
    end
  end

  def fetch_index(language, word) do
    case word_to_index(language) do
      {:ok, wordlist} ->
        case Map.fetch(wordlist, word) do
          :error -> {:error, invalid_word(word, language)}
          {:ok, index} -> {:ok, index}
        end

      error ->
        error
    end
  end

  def fetch_index!(language, word) do
    case fetch_index(language, word) do
      {:ok, index} -> index
      {:error, reason} -> raise MnemonistError, reason
    end
  end

  def has_word?(language, word), do: match?({:ok, _}, fetch_index(language, word))

  defp word_to_index(language) do
    case Map.fetch(@word_to_index, to_string(language)) do
      :error -> {:error, invalid_language(language)}
      {:ok, value} -> {:ok, value}
    end
  end

  defp index_to_word(language) do
    case Map.fetch(@index_to_word, to_string(language)) do
      :error -> {:error, invalid_language(language)}
      {:ok, value} -> {:ok, value}
    end
  end

  defp invalid_language(language), do: "Invalid mnemonic language #{inspect(language)}."

  defp invalid_word(word, language),
    do: "Invalid mnemonic word (#{inspect(word)}) for language #{inspect(language)}."

  defp invalid_index(index, language),
    do: "Invalid mnemonic index (#{inspect(index)}) for language #{inspect(language)}."
end
