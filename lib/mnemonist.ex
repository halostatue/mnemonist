defmodule Mnemonist do
  @moduledoc """
  Mnemonist is a complete modern implementation of [BIP-39][bip39] for Elixir. It supports
  all BIP-39 supported language wordlists and is validated against the
  [Trezor test vectors][trezor-test-vectors].

  Mnemonist is largely based on [LanfordCai/mnemonic][lc-mnemonic]'s implementation,
  including the use of `m::crypto` for PBKDF2 implementation, but has been influenced by
  the following projects:

  - [aerosol/mnemo](https://github.com/aerosol/mnemo)
  - [ayrat555/mnemoniac](https://github.com/ayrat555/mnemoniac)
  - [izelnakri/mnemonic](https://github.com/izelnakri/mnemonic)
  - [rudebono/bip39](https://github.com/rudebono/bip39)
  - [trezor/python-mnemonic](https://github.com/trezor/python-mnemonic)

  [bip39]: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
  [bip39-wordlists]: https://github.com/bitcoin/bips/blob/master/bip-0039/bip-0039-wordlists.md
  [trezor-test-vectors]: https://github.com/trezor/python-mnemonic/blob/master/vectors.json
  [lc-mnemonic]: https://github.com/LanfordCai/mnemonic
  """

  alias Mnemonist.Crypto
  alias Mnemonist.Wordlist

  languages = [
    :chinese_simplified,
    :chinese_traditional,
    :czech,
    :english,
    :french,
    :italian,
    :japanese,
    :korean,
    :portuguese,
    :russian,
    :spanish,
    :turkish
  ]

  @supported_languages_atom languages
  @supported_languages languages ++ Enum.map(languages, &to_string/1)

  {language_last, language_rest} =
    @supported_languages_atom
    |> Enum.map(&"`#{&1}`")
    |> List.pop_at(-1)

  language_rest = Enum.join(language_rest, ", ")

  @word_numbers_to_entropy_bits %{12 => 128, 15 => 160, 18 => 192, 21 => 224, 24 => 256}
  @valid_mnemonic_length Enum.sort(Map.keys(@word_numbers_to_entropy_bits))

  @valid_entropy_length Enum.sort(Map.values(@word_numbers_to_entropy_bits))

  @default_entropy_length Enum.max(@valid_entropy_length)
  @default_language :english

  doc_supported_languages =
    "Supported languages are:\n\n" <>
      Enum.map_join(@supported_languages_atom, "\n", fn language ->
        name =
          case String.split(to_string(language), "_") do
            [name, extra] -> "#{String.capitalize(name)} (#{String.capitalize(extra)})"
            [name] -> String.capitalize(name)
          end

        "- `#{inspect(language)}` / `\"#{language}\"`: #{name}"
      end) <> "\n\nThe default `language` is `#{inspect(@default_language)}`.\n"

  doc_allowed_strength =
    "Allowed mnemonic strength can be provided as words or bits.\n\n" <>
      Enum.map_join(@valid_mnemonic_length, "\n", fn word_length ->
        "- #{word_length} words (#{@word_numbers_to_entropy_bits[word_length]})"
      end) <> "\n\nThe default `strength` is #{@default_entropy_length} bits."

  {entropy_last, entropy_rest} = List.pop_at(@valid_entropy_length, -1)
  entropy_rest = Enum.join(entropy_rest, ", ")

  doc_allowed_entropy_length = """
  Allowed entropy length (strength) is #{entropy_rest}, and #{entropy_last} bits.
  """

  {mnemonic_last, mnemonic_rest} = List.pop_at(@valid_mnemonic_length, -1)
  mnemonic_rest = Enum.join(mnemonic_rest, ", ")

  doc_allowed_mnemonic_length = """
  Allowed mnemonic length is #{mnemonic_rest}, and #{mnemonic_last} words.
  """

  @ideographic_space "\u3000"

  @doc """
  Determines if `integer` is a valid BIP-39 entropy length.

  Returns `true` if the given `integer` is one of #{entropy_rest}, or #{entropy_last}.
  Otherwise, it returns `false`.

  Allowed in guard clauses.

  ## Examples

  ```elixir
  iex> Mnemonist.is_valid_entropy_bits(128)
  true

  iex> Mnemonist.is_valid_entropy_bits(31)
  false

  iex> Mnemonist.is_valid_entropy_bits(-5)
  false

  iex> Mnemonist.is_valid_entropy_bits(0)
  false

  iex> Mnemonist.is_valid_entropy_bits(1024)
  false
  ```
  """
  defguard is_valid_entropy_bits(integer) when integer in @valid_entropy_length

  @doc """
  Determines if `entropy` is a bitstring with a valid number of BIP-39 entropy bits.

  Returns `true` if the given `entropy` is a bitstring with #{entropy_rest}, or
  #{entropy_last} bits. Otherwise, it returns `false`.

  Allowed in guard clauses.

  ## Examples

  ```elixir
  iex> Mnemonist.is_valid_entropy(<<0::128>>)
  true

  iex> Mnemonist.is_valid_entropy(<<0::1024>>)
  false

  iex> Mnemonist.is_valid_entropy(<<0::8>>)
  false

  iex> Mnemonist.is_valid_entropy(<<0::31>>)
  false
  ```
  """
  defguard is_valid_entropy(entropy)
           when is_bitstring(entropy) and is_valid_entropy_bits(bit_size(entropy))

  @doc """
  Determines if `integer` is a count of a valid number of BIP-39 mnemonic words.

  Returns `true` if the given `integer` is one of #{mnemonic_rest}, or #{mnemonic_last}
  bits. Otherwise, it returns `false`.

  Allowed in guard clauses.

  ## Examples

  ```elixir
  iex> Mnemonist.is_valid_mnemonic_length(12)
  true

  iex> Mnemonist.is_valid_mnemonic_length(1)
  false

  iex> Mnemonist.is_valid_mnemonic_length(-5)
  false

  iex> Mnemonist.is_valid_mnemonic_length(48)
  false
  ```
  """
  defguard is_valid_mnemonic_length(integer) when integer in @valid_mnemonic_length

  @doc """
  Determines if `integer` is a valid BIP-39 entropy length or a count of a valid number of
  BIP-39 mnemonic words.

  Returns `true` if the given `integer` is one of:

  - #{mnemonic_rest}, or #{mnemonic_last} words
  - #{entropy_rest}, or #{entropy_last} bits.

  Otherwise, it returns `false`.

  Allowed in guard clauses.

  ## Examples

  ```elixir
  iex> Mnemonist.is_valid_strength(128)
  true

  iex> Mnemonist.is_valid_strength(12)
  true

  iex> Mnemonist.is_valid_strength(31)
  false

  iex> Mnemonist.is_valid_strength(-5)
  false

  iex> Mnemonist.is_valid_strength(0)
  false

  iex> Mnemonist.is_valid_strength(1024)
  false
  ```
  """
  defguard is_valid_strength(integer)
           when is_valid_entropy_bits(integer) or is_valid_mnemonic_length(integer)

  @doc """
  Determines if `language` is a valid BIP-39 entropy language.

  Returns `true` if the given `language` is one of #{language_rest}, or #{language_last},
  as a `t:binary/0` or `t:atom/0`. Otherwise, it returns `false`.

  Allowed in guard clauses.

  ## Examples

  ```elixir
  iex> Mnemonist.is_supported_language(:english)
  true

  iex> Mnemonist.is_supported_language("english")
  true

  iex> Mnemonist.is_supported_language(:czech)
  true

  iex> Mnemonist.is_supported_language("czech")
  true

  iex> Mnemonist.is_supported_language(:klingon)
  false

  iex> Mnemonist.is_supported_language("klingon")
  false
  ```
  """
  defguard is_supported_language(language)
           when language in @supported_languages

  @typedoc """
  Languages with defined mnemonic word lists, either as a `t:String.t/0` or an `t:atom/0`.

  #{doc_supported_languages}
  """
  @type language ::
          binary()
          | unquote(Enum.reduce(@supported_languages_atom, &{:|, [], [&1, &2]}))

  @doc """
  Generate a random mnemonic sentence using the mnemonic `language`. The `strength`
  parameter can be provided either as the number of words or the bits of entropy.
  Returns `{:ok, mnemonic}` or `{:error, reason}`.

  #{doc_allowed_strength}

  #{doc_supported_languages}
  """
  @spec generate_mnemonic(strength :: pos_integer() | language(), language()) ::
          {:ok, String.t()} | {:error, String.t()}
  def generate_mnemonic(strength \\ @default_entropy_length, language \\ @default_language)

  def generate_mnemonic(strength, language) when is_valid_entropy_bits(strength) and is_supported_language(language) do
    strength
    |> div(8)
    |> :crypto.strong_rand_bytes()
    |> mnemonic_from_entropy(language)
  end

  def generate_mnemonic(count, language) when is_valid_mnemonic_length(count) and is_supported_language(language) do
    generate_mnemonic(@word_numbers_to_entropy_bits[count], language)
  end

  def generate_mnemonic(language, @default_language) when is_supported_language(language) do
    generate_mnemonic(@default_entropy_length, language)
  end

  def generate_mnemonic(language, @default_language)
      when (is_binary(language) or is_atom(language)) and not is_supported_language(language) do
    invalid_language(language)
  end

  def generate_mnemonic(strength, language) when is_valid_strength(strength) do
    invalid_language(language)
  end

  def generate_mnemonic(strength, language) when is_supported_language(language) do
    invalid_strength(strength)
  end

  def generate_mnemonic(strength, language) do
    invalid_strength_language(strength, language)
  end

  @doc """
  Generate a random mnemonic sentence using the mnemonic `language`. The `strength`
  parameter can be provided either as the number of words or the bits of entropy.
  Raises an exception on error.

  #{doc_allowed_strength}

  #{doc_supported_languages}
  """
  @spec generate_mnemonic!(strength :: pos_integer() | language(), language()) :: String.t()
  def generate_mnemonic!(strength \\ @default_entropy_length, language \\ @default_language) do
    case generate_mnemonic(strength, language) do
      {:ok, mnemonic} -> mnemonic
      {:error, reason} -> raise MnemonistError, reason
    end
  end

  @doc """
  Generate mnemonic sentences from the given `entropy` and `language`. Returns
  `{:ok, sentence}` or `{:error, reason}`.

  The provided `entropy` is treated as the raw entropy bitstring and an appropriate
  checksum will be appended during processing.

  #{doc_allowed_entropy_length}

  #{doc_supported_languages}

  ## Examples

  ```elixir
  iex> entropy = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  iex> Mnemonist.mnemonic_from_entropy(entropy, :english)
  {:ok, "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"}

  iex> entropy = Base.decode16!("00000000000000000000000000000000", case: :mixed)
  iex> Mnemonist.mnemonic_from_entropy(entropy, :english)
  {:ok, "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"}
  ```
  """
  @spec mnemonic_from_entropy(binary(), language()) :: {:ok, String.t()} | {:error, term()}
  def mnemonic_from_entropy(entropy, language \\ @default_language)

  def mnemonic_from_entropy(entropy, language) when is_valid_entropy(entropy) and is_supported_language(language) do
    entropy
    |> append_checksum()
    |> do_generate_mnemonic(language)
  end

  def mnemonic_from_entropy(entropy, language) when is_supported_language(language) do
    invalid_entropy(entropy)
  end

  def mnemonic_from_entropy(entropy, language) when is_valid_entropy(entropy) do
    invalid_language(language)
  end

  def mnemonic_from_entropy(entropy, language) do
    invalid_entropy_language(entropy, language)
  end

  @doc """
  Generate mnemonic sentences with given entropy (from an external source) and mnemonic
  language. Raises an exception on error.

  #{doc_allowed_entropy_length}

  #{doc_supported_languages}

  ## Examples

  ```elixir
  iex> entropy = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  iex> Mnemonist.mnemonic_from_entropy!(entropy, :english)
  "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  ```
  """
  @spec mnemonic_from_entropy!(entropy :: binary(), language()) :: String.t()
  def mnemonic_from_entropy!(entropy, language \\ @default_language) do
    case mnemonic_from_entropy(entropy, language) do
      {:ok, mnemonic} -> mnemonic
      {:error, reason} -> raise MnemonistError, reason
    end
  end

  @doc """
  Produce the seed for the given `mnemonic`, `passphrase`, and `language`. Returns
  `{:ok, binary()}` or `{:error, term()}`.

  The produced seed will be 64 bytes that can be passed to an algorithm compatible with
  [BIP-32][bip32]/[BIP-44][bip44] HD wallet derivation.

  The `mnemonic` and `passphrase` values will be normalized to Unicode
  [Normalization Form KD][nfkd].

  Note that the convenience form `mnemonic_to_seed(mnemonic, language)` only works when
  the language is provided in the atom form. Otherwise, the language will be treated as
  the passphrase.

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms
  [bip32]: https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
  [bip44]: https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki

  ## Examples

  ```elixir
  iex> mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  iex> Mnemonist.mnemonic_to_seed(mnemonic, "TREZOR", :english)
  {:ok, <<197, 82, 87, 195, 96, 192, 124, 114, 2, 154, 235, 193, 181, 60, 5, 237, 3, 98,
    173, 163, 142, 173, 62, 62, 158, 250, 55, 8, 229, 52, 149, 83, 31, 9, 166, 152,
    117, 153, 209, 130, 100, 193, 225, 201, 47, 44, 241, 65, 99, 12, 122, 60, 74,
    183, 200, 27, 47, 0, 22, 152, 231, 70, 59, 4>>}
  ```
  """
  @spec mnemonic_to_seed(
          mnemonic :: String.t(),
          passphrase :: String.t() | language(),
          language()
        ) :: {:ok, binary()} | {:error, term()}
  def mnemonic_to_seed(mnemonic, passphrase \\ "", language \\ @default_language)

  def mnemonic_to_seed(mnemonic, passphrase, @default_language)
      when is_atom(passphrase) and is_supported_language(passphrase) do
    mnemonic_to_seed(mnemonic, "", passphrase)
  end

  def mnemonic_to_seed(mnemonic, passphrase, language)
      when is_binary(mnemonic) and is_binary(passphrase) and is_supported_language(language) do
    mnemonic = normalize_nkfd(mnemonic)

    with {:ok, _entropy} <- mnemonic_to_entropy(mnemonic, language) do
      {:ok, Crypto.pbkdf2(mnemonic, salt(passphrase))}
    end
  end

  def mnemonic_to_seed(mnemonic, _passphrase, _language) when not is_binary(mnemonic) do
    {:error, "Mnemonic must be a binary string."}
  end

  def mnemonic_to_seed(_mnemonic, passphrase, _language) when not is_binary(passphrase) do
    {:error, "Passphrase must be a binary string."}
  end

  def mnemonic_to_seed(_mnemonic, _passphrase, language) when not is_supported_language(language) do
    invalid_language(language)
  end

  @doc """
  Produce the seed for the given mnemonic, passphrase, and language. The seed is 64 bytes.
  Raises an exception on error.

  The mnemonic will be normalized to Unicode [Normalization Form KD][nfkd].

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms

  ## Examples

  ```elixir
  iex> mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  iex> Mnemonist.mnemonic_to_seed!(mnemonic, "TREZOR", :english)
  <<197, 82, 87, 195, 96, 192, 124, 114, 2, 154, 235, 193, 181, 60, 5, 237, 3, 98,
    173, 163, 142, 173, 62, 62, 158, 250, 55, 8, 229, 52, 149, 83, 31, 9, 166, 152,
    117, 153, 209, 130, 100, 193, 225, 201, 47, 44, 241, 65, 99, 12, 122, 60, 74,
    183, 200, 27, 47, 0, 22, 152, 231, 70, 59, 4>>
  ```
  """
  @spec mnemonic_to_seed!(mnemonic :: String.t(), passphrase :: String.t(), language()) :: binary()
  def mnemonic_to_seed!(mnemonic, passphrase \\ "", language \\ @default_language) do
    case mnemonic_to_seed(mnemonic, passphrase, language) do
      {:ok, seed} -> seed
      {:error, reason} -> raise MnemonistError, reason
    end
  end

  @doc """
  Converts the given mnemonic to its binary entropy. Returns `{:ok, entropy}` or
  `{:error, reason}`.

  Checks that the provided number of words is valid, their existence in the language
  wordlist, and finally the checksum value.

  The mnemonic will be normalized to Unicode [Normalization Form KD][nfkd].

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms

  #{doc_supported_languages}

  #{doc_allowed_mnemonic_length}

  ## Examples

  ```elixir
  iex> mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  iex> Mnemonist.mnemonic_to_entropy(mnemonic, :english)
  {:ok, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
  ```
  """
  @spec mnemonic_to_entropy(mnemonic :: String.t(), language()) ::
          {:ok, binary()} | {:error, term()}
  def mnemonic_to_entropy(mnemonic, language \\ @default_language)

  def mnemonic_to_entropy(mnemonic, language) when is_binary(mnemonic) and is_supported_language(language) do
    mnemonic
    |> mnemonic_to_words()
    |> words_to_checksummed_entropy(language)
    |> checksummed_entropy_to_entropy()
  end

  def mnemonic_to_entropy(mnemonic, _language) when not is_binary(mnemonic) do
    {:error, "Mnemonic must be a binary string."}
  end

  def mnemonic_to_entropy(_mnemonic, language) when not is_supported_language(language) do
    invalid_language(language)
  end

  @doc """
  Converts the given mnemonic to its binary entropy. Raises an exception on error.

  Checks that the provided number of words is valid, their existence in the language
  wordlist, and finally the checksum value.

  The mnemonic will be normalized to Unicode [Normalization Form KD][nfkd].

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms

  #{doc_supported_languages}

  #{doc_allowed_mnemonic_length}

  ## Examples

  ```elixir
  iex> mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  iex> Mnemonist.mnemonic_to_entropy!(mnemonic, :english)
  <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  ```
  """
  @spec mnemonic_to_entropy!(mnemonic :: String.t(), language()) :: binary()
  def mnemonic_to_entropy!(mnemonic, language \\ @default_language) do
    case mnemonic_to_entropy(mnemonic, language) do
      {:ok, entropy} -> entropy
      {:error, reason} -> raise MnemonistError, reason
    end
  end

  @doc """
  Returns `true` if the provided `mnemonic` is valid for `language`.

  The mnemonic will be normalized to Unicode [Normalization Form KD][nfkd].

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms

  #{doc_supported_languages}
  """
  @spec valid_mnemonic?(mnemonic :: String.t(), language()) :: boolean()
  def valid_mnemonic?(mnemonic, language \\ @default_language) do
    match?({:ok, _}, mnemonic_to_entropy(mnemonic, language))
  end

  @doc """
  Retrieves the word for the supported language by the provided index value. Returns
  `{:ok, word}` or `:error`.
  """
  @spec fetch_mnemonic_word(non_neg_integer(), language()) ::
          {:ok, String.t()} | {:error, String.t()}
  def fetch_mnemonic_word(index, language \\ @default_language) do
    Wordlist.fetch_word(language, index)
  end

  @doc """
  Retrieves the word for the supported language by the provided index value. Raises an
  exception on error.
  """
  @spec fetch_mnemonic_word!(non_neg_integer(), language()) :: String.t()
  def fetch_mnemonic_word!(index, language \\ @default_language) do
    Wordlist.fetch_word!(language, index)
  end

  @doc """
  Retrieves the index for a given word for the supported language. Returns `{:ok, word}`
  or `:error`.

  The mnemonic word will be normalized to Unicode [Normalization Form KD][nfkd].

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms
  """
  @spec fetch_mnemonic_index(String.t(), language()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
  def fetch_mnemonic_index(word, language \\ @default_language) when is_binary(word) do
    Wordlist.fetch_index(language, normalize_nkfd(word))
  end

  @doc """
  Retrieves the index for a given word for the supported language. Raises an exception on
  error.

  The mnemonic word will be normalized to Unicode [Normalization Form KD][nfkd].

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms
  """
  @spec fetch_mnemonic_index!(String.t(), language()) :: {:ok, non_neg_integer()} | :error
  def fetch_mnemonic_index!(word, language \\ @default_language) when is_binary(word) do
    Wordlist.fetch_index!(language, normalize_nkfd(word))
  end

  @doc """
  Scan the mnemonic until the language is unambiguous. Returns `{:ok, language()}`
  when the language is resolved.

  There are 100 words that are used in both English and French, and 1,275 words that are
  used in both Chinsese (Simplified) and Chinese (Traditional), so the mnemonic will be
  searched until there is no overlap. If the mnemonic phrase remains ambiguous, returns
  `{:error, :ambiguous, [language()]}`.

  If a word is used that is unrecognized in any language, `{:error, :invalid, String.t()}` will be
  returned with the word that does not match.
  """
  @spec detect_mnemonic_language(String.t()) ::
          {:ok, language()}
          | {:error, :ambiguous, [language()]}
          | {:error, :invalid, String.t()}
          | {:error, String.t()}
  def detect_mnemonic_language(mnemonic) do
    case mnemonic_to_words(mnemonic) do
      {:ok, words} ->
        case find_language_candidates(words) do
          [] ->
            raise MnemonistError,
                  "Please file a bug at https://github.com/halostatue/mnemonist/issues as this should not be possible"

          [language] ->
            {:ok, language}

          [_ | _] = candidates ->
            {:error, :ambiguous, candidates}

          {:ok, language} ->
            {:ok, language}

          error ->
            error
        end

      error ->
        error
    end
  end

  @doc """
  Scan the mnemonic until the language is unambiguous. Returns `language()` when the
  language is resolved and raises an exception on error.

  There are 100 words that are used in both English and French, and 1,275 words that are
  used in both Chinsese (Simplified) and Chinese (Traditional), so the mnemonic will be
  searched until there is no overlap. If the mnemonic phrase remains ambiguous, raises an
  exception.

  If a word is used that is unrecognized in any language, raises an exception.

  The mnemonic will be normalized to Unicode [Normalization Form KD][nfkd].

  [nfkd]: https://www.unicode.org/reports/tr15/#Norm_Forms
  """
  @spec detect_mnemonic_language!(String.t()) :: language()
  def detect_mnemonic_language!(mnemonic) do
    case detect_mnemonic_language(mnemonic) do
      {:ok, language} ->
        language

      {:error, :ambiguous, candidates} ->
        raise MnemonistError, "Mnemonic language ambiguous between #{inspect(candidates)}"

      {:error, :invalid, word} ->
        raise MnemonistError, "Mnemonic language unrecognized for #{inspect(word)}"

      {:error, reason} ->
        raise MnemonistError, reason
    end
  end

  def __supported_languages, do: @supported_languages_atom

  def __word_numbers_to_entropy_bits, do: @word_numbers_to_entropy_bits

  defp find_language_candidates(words) do
    Enum.reduce_while(words, __supported_languages(), &check_language_candidate/2)
  end

  defp check_language_candidate(word, candidates) do
    case Enum.filter(candidates, &Wordlist.has_word?(&1, word)) do
      [] -> {:halt, {:error, :invalid, word}}
      [language] -> {:halt, {:ok, language}}
      candidates -> {:cont, candidates}
    end
  end

  defp salt(passphrase), do: normalize_nkfd("mnemonic" <> passphrase)

  defp append_checksum(entropy) do
    bits =
      entropy
      |> bit_size()
      |> div(32)

    <<checksum::bitstring-size(bits), _rest::bitstring>> = :crypto.hash(:sha256, entropy)
    <<entropy::bitstring, checksum::bitstring>>
  end

  defp do_generate_mnemonic(entropy, language) do
    joiner =
      case language do
        :japanese -> @ideographic_space
        _otherwise -> " "
      end

    {:ok,
     entropy
     |> split_to_group()
     |> Enum.map_join(joiner, &Wordlist.fetch_word!(language, &1))}
  end

  defp split_to_group(entropy), do: do_split_to_group(entropy, [])

  defp do_split_to_group(<<>>, groups), do: groups

  defp do_split_to_group(<<group::11, rest::bitstring>>, groups), do: do_split_to_group(rest, groups ++ [group])

  defp mnemonic_to_words(mnemonic) do
    words =
      mnemonic
      |> String.trim()
      |> normalize_nkfd()
      |> String.split([" ", @ideographic_space])

    length = length(words)

    if length in @valid_mnemonic_length do
      {:ok, words}
    else
      invalid_mnemonic_words(length)
    end
  end

  defp words_to_checksummed_entropy({:error, error}, _lang), do: {:error, error}

  defp words_to_checksummed_entropy({:ok, words}, language) when is_list(words) do
    indexes =
      Enum.reduce_while(words, [], fn word, acc ->
        case Wordlist.fetch_index(language, word) do
          {:error, reason} -> {:halt, {:error, reason}}
          {:ok, index} -> {:cont, [index | acc]}
        end
      end)

    case indexes do
      {:error, reason} ->
        {:error, reason}

      indexes ->
        {:ok, for(index <- Enum.reverse(indexes), do: <<index::size(11)>>, into: "")}
    end
  end

  defp checksummed_entropy_to_entropy({:error, error}), do: {:error, error}

  defp checksummed_entropy_to_entropy({:ok, checksummed_entropy}) do
    checksummed_entropy
    |> extract_entropy()
    |> validate_checksum()
  end

  defp extract_entropy(checksummed_entropy) when is_bitstring(checksummed_entropy) do
    # divider_index = floor(bit_size(checksummed_entropy) / 33) * 32
    # <<entropy::size(divider_index), checksum::bitstring>> = checksummed_entropy
    # ent = <<entropy::size(divider_index)>>

    ent =
      bit_size(checksummed_entropy)
      |> Kernel.*(32)
      |> div(33)

    bits = div(ent, 32)

    case checksummed_entropy do
      <<entropy::bitstring-size(ent), checksum::bitstring-size(bits)>> -> {:ok, entropy, checksum}
      _error -> {:error, :invalid_mnemonic}
    end
  end

  defp validate_checksum({:error, error}), do: {:error, error}

  defp validate_checksum({:ok, entropy, checksum}) do
    bits = bit_size(checksum)

    <<valid_checksum::bitstring-size(bits), _rest::bitstring>> = :crypto.hash(:sha256, entropy)

    if valid_checksum == checksum do
      {:ok, entropy}
    else
      {:error, :invalid_mnemonic_checksum}
    end
  end

  defp normalize_nkfd(string), do: :unicode.characters_to_nfkd_binary(string)

  defp invalid_language(language) do
    {:error, "Invalid mnemonic language #{inspect(language)}, must be one of: #{inspect(__supported_languages())}"}
  end

  defp invalid_strength(strength) do
    {:error, "Invalid mnemonic strength #{inspect(strength)}."}
  end

  defp invalid_strength_language(strength, language) do
    {:error, "Invalid mnemonic strength #{inspect(strength)} and language #{inspect(language)}."}
  end

  defp invalid_entropy(entropy) do
    {:error, "Invalid entropy value with #{bit_size(entropy)} bits."}
  end

  defp invalid_entropy_language(entropy, language) do
    {:error, "Invalid entropy value with #{bit_size(entropy)} bits and language #{inspect(language)}."}
  end

  defp invalid_mnemonic_words(count) do
    {:error, "Invalid mnemonic word count #{count}."}
  end
end
