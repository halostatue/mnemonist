defmodule MnemonistTest do
  use ExUnit.Case, async: true

  import Mnemonist

  doctest Mnemonist

  @mnemonic_abandon_about "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  @mnemonic_abaco_abierto "ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco abierto"

  @entropy_good <<0::128>>
  @entropy_bad <<0::127>>

  @seed_english_default <<94, 176, 11, 189, 220, 240, 105, 8, 72, 137, 168, 171, 145, 85, 86, 129,
                          101, 245, 196, 83, 204, 184, 94, 112, 129, 26, 174, 214, 246, 218, 95,
                          193, 154, 90, 196, 11, 56, 156, 211, 112, 208, 134, 32, 109, 236, 138,
                          166, 196, 61, 174, 166, 105, 15, 32, 173, 61, 141, 72, 178, 210, 206, 158,
                          56, 228>>
  @seed_english_trezor <<197, 82, 87, 195, 96, 192, 124, 114, 2, 154, 235, 193, 181, 60, 5, 237, 3,
                         98, 173, 163, 142, 173, 62, 62, 158, 250, 55, 8, 229, 52, 149, 83, 31, 9,
                         166, 152, 117, 153, 209, 130, 100, 193, 225, 201, 47, 44, 241, 65, 99, 12,
                         122, 60, 74, 183, 200, 27, 47, 0, 22, 152, 231, 70, 59, 4>>

  @seed_spanish_default <<253, 254, 155, 124, 122, 94, 80, 121, 187, 54, 214, 56, 24, 56, 134, 122,
                          52, 53, 141, 176, 160, 48, 125, 6, 10, 219, 175, 94, 218, 219, 8, 176,
                          168, 124, 6, 237, 225, 169, 106, 253, 133, 102, 239, 73, 151, 146, 255,
                          203, 211, 127, 67, 246, 245, 84, 250, 52, 65, 56, 102, 14, 172, 222, 252,
                          248>>
  @seed_spanish_trezor <<41, 162, 238, 22, 222, 71, 208, 112, 37, 222, 55, 231, 217, 197, 150, 134,
                         148, 57, 249, 188, 210, 106, 112, 45, 43, 174, 100, 219, 43, 240, 246, 131,
                         131, 132, 28, 84, 68, 181, 179, 189, 57, 221, 114, 13, 46, 190, 89, 150,
                         158, 17, 14, 89, 85, 200, 230, 211, 44, 108, 50, 148, 253, 135, 67, 155>>

  @trezor_vectors :mnemonist
                  |> :code.priv_dir()
                  |> Path.join("/vectors.json")
                  |> File.read!()
                  |> Jason.decode!()

  @vector_passphrase "TREZOR"

  for {language, vectors} <- @trezor_vectors do
    language = String.to_existing_atom(language)

    describe "trezor-vectors:#{language}" do
      for {[entropy_hex, mnemonic, seed_hex, master_hd_key], i} <- Enum.with_index(vectors) do
        entropy = Base.decode16!(entropy_hex, case: :mixed)
        seed = Base.decode16!(seed_hex, case: :mixed)

        test "mnemonic_from_entropy/2 index #{i}" do
          assert {:ok, unquote(mnemonic)} ==
                   mnemonic_from_entropy(unquote(entropy), unquote(language))
        end

        test "mnemonic_from_entropy!/2 index #{i}" do
          assert unquote(mnemonic) == mnemonic_from_entropy!(unquote(entropy), unquote(language))
        end

        test "mnemonic_to_entropy/2 index #{i}" do
          assert {:ok, unquote(entropy)} ==
                   mnemonic_to_entropy(unquote(mnemonic), unquote(language))
        end

        test "mnemonic_to_entropy!/2 index #{i}" do
          assert unquote(entropy) == mnemonic_to_entropy!(unquote(mnemonic), unquote(language))
        end

        test "valid_mnemonic?/2 index #{i}" do
          assert valid_mnemonic?(unquote(mnemonic), unquote(language))

          refute valid_mnemonic?(
                   unquote(mnemonic),
                   if(unquote(language) == :english, do: "spanish", else: "english")
                 )
        end

        test "mnemonic_to_seed/3 index #{i}" do
          assert {:ok, unquote(seed)} ==
                   mnemonic_to_seed(unquote(mnemonic), @vector_passphrase, unquote(language))
        end

        test "mnemonic_to_seed/3 index #{i} (with NFKC encoding)" do
          mnemonic = :unicode.characters_to_nfkc_binary(unquote(mnemonic))

          assert {:ok, unquote(seed)} ==
                   mnemonic_to_seed(mnemonic, @vector_passphrase, unquote(language))
        end

        test "HD wallet (bitcoin) index #{i}" do
          assert {:ok, seed} =
                   mnemonic_to_seed(unquote(mnemonic), @vector_passphrase, unquote(language))

          assert unquote(master_hd_key) == to_hd_master_key(seed)
        end
      end
    end
  end

  describe "generate_mnemonic/2" do
    for {words, bits} <- Mnemonist.__word_numbers_to_entropy_bits() do
      test "generate_mnemonic(#{bits}) generates #{words} English words" do
        assert {:ok, mnemonic} = generate_mnemonic(unquote(bits))

        assert unquote(words) ==
                 mnemonic
                 |> String.split(" ")
                 |> length()

        assert valid_mnemonic?(mnemonic, :english)
      end

      test "generate_mnemonic(#{words}) generates #{words} English words" do
        assert {:ok, mnemonic} = generate_mnemonic(unquote(words))

        assert unquote(words) ==
                 mnemonic
                 |> String.split(" ")
                 |> length()

        assert valid_mnemonic?(mnemonic, :english)
      end
    end

    test "generate_mnemonic() generates 24 English words" do
      assert {:ok, mnemonic} = generate_mnemonic()

      assert 24 ==
               mnemonic
               |> String.split(" ")
               |> length()

      assert valid_mnemonic?(mnemonic, :english)
    end

    test "generate_mnemonic(\"spanish\") generates 24 Spanish words" do
      assert {:ok, mnemonic} = generate_mnemonic("spanish")

      assert 24 ==
               mnemonic
               |> String.split(" ")
               |> length()

      assert valid_mnemonic?(mnemonic, "spanish")
    end

    test "generate_mnemonic(:klingon) returns an error" do
      assert {:error, "Invalid mnemonic language :klingon, must be one of" <> _} =
               generate_mnemonic(:klingon)
    end

    test "generate_mnemonic(24, :klingon) returns an error" do
      assert {:error, "Invalid mnemonic language :klingon, must be one of" <> _} =
               generate_mnemonic(24, :klingon)
    end

    test "generate_mnemonic(37) returns an error" do
      assert {:error, "Invalid mnemonic strength 37."} = generate_mnemonic(37)
    end

    test "generate_mnemonic(37, \"spanish\") returns an error" do
      assert {:error, "Invalid mnemonic strength 37."} = generate_mnemonic(37, "spanish")
    end

    test "generate_mnemonic(37, :klingon) returns an error" do
      assert {:error, "Invalid mnemonic strength 37 and language :klingon."} =
               generate_mnemonic(37, :klingon)
    end
  end

  describe "generate_mnemonic!/2" do
    for {words, bits} <- Mnemonist.__word_numbers_to_entropy_bits() do
      test "generate_mnemonic!(#{bits}) generates #{words} English words" do
        assert mnemonic = generate_mnemonic!(unquote(bits))

        assert unquote(words) ==
                 mnemonic
                 |> String.split(" ")
                 |> length()

        assert valid_mnemonic?(mnemonic, :english)
      end

      test "generate_mnemonic!(#{words}) generates #{words} English words" do
        assert mnemonic = generate_mnemonic!(unquote(words))

        assert unquote(words) ==
                 mnemonic
                 |> String.split(" ")
                 |> length()

        assert valid_mnemonic?(mnemonic, :english)
      end
    end

    test "generate_mnemonic!() generates 24 English words" do
      assert mnemonic = generate_mnemonic!()

      assert 24 ==
               mnemonic
               |> String.split(" ")
               |> length()

      assert valid_mnemonic?(mnemonic, :english)
    end

    test "generate_mnemonic!(\"spanish\") generates 24 Spanish words" do
      assert mnemonic = generate_mnemonic!("spanish")

      assert 24 ==
               mnemonic
               |> String.split(" ")
               |> length()

      assert valid_mnemonic?(mnemonic, "spanish")
    end

    test "generate_mnemonic!(:klingon) returns an error" do
      assert_raise MnemonistError, ~r/Invalid mnemonic language :klingon, must be one of/, fn ->
        generate_mnemonic!(:klingon)
      end
    end

    test "generate_mnemonic(24, :klingon) returns an error" do
      assert_raise MnemonistError, ~r/Invalid mnemonic language :klingon, must be one of/, fn ->
        generate_mnemonic!(24, :klingon)
      end
    end

    test "generate_mnemonic(37) returns an error" do
      assert_raise MnemonistError, ~r/Invalid mnemonic strength 37./, fn ->
        generate_mnemonic!(37)
      end
    end

    test "generate_mnemonic(37, \"spanish\") returns an error" do
      assert_raise MnemonistError, ~r/Invalid mnemonic strength 37./, fn ->
        generate_mnemonic!(37, "spanish")
      end
    end

    test "generate_mnemonic(37, :klingon) returns an error" do
      assert_raise MnemonistError, ~r/Invalid mnemonic strength 37 and language :klingon./, fn ->
        generate_mnemonic!(37, :klingon)
      end
    end
  end

  describe "mnemonic_from_entropy/2" do
    @mnemonic_abaco_abierto "ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco ábaco abierto"

    test "mnemonic_from_entropy(<<0::128>>) produces a valid English mnemonic" do
      assert {:ok, @mnemonic_abandon_about} == mnemonic_from_entropy(@entropy_good)
    end

    test "mnemonic_from_entropy(<<0::128>>, \"spanish\") produces a valid Spanish mnemonic" do
      assert {:ok, @mnemonic_abaco_abierto} == mnemonic_from_entropy(@entropy_good, "spanish")
    end

    test "mnemonic_from_entropy(<<0::128>>, :klingon) returns an error" do
      assert {:error, "Invalid mnemonic language :klingon, must be one of:" <> _} =
               mnemonic_from_entropy(@entropy_good, :klingon)
    end

    test "mnemonic_from_entropy(<<0::127>>) returns an error" do
      assert {:error, "Invalid entropy value with 127 bits."} == mnemonic_from_entropy(@entropy_bad)
    end

    test "mnemonic_from_entropy(<<0::127>>, :klingon) returns an error" do
      assert {:error, "Invalid entropy value with 127 bits and language :klingon."} ==
               mnemonic_from_entropy(@entropy_bad, :klingon)
    end
  end

  describe "mnemonic_from_entropy!/2" do
    test "mnemonic_from_entropy!(<<0::128>>) produces a valid English mnemonic" do
      assert @mnemonic_abandon_about == mnemonic_from_entropy!(@entropy_good)
    end

    test "mnemonic_from_entropy!(<<0::128>>, \"spanish\") produces a valid Spanish mnemonic" do
      assert @mnemonic_abaco_abierto == mnemonic_from_entropy!(@entropy_good, "spanish")
    end

    test "mnemonic_from_entropy!(<<0::128>>, :klingon) returns an error" do
      assert_raise MnemonistError, ~r/Invalid mnemonic language :klingon, must be one of/, fn ->
        mnemonic_from_entropy!(@entropy_good, :klingon)
      end
    end

    test "mnemonic_from_entropy(<<0::127>>) returns an error" do
      assert_raise MnemonistError, ~r/Invalid entropy value with 127 bits./, fn ->
        mnemonic_from_entropy!(@entropy_bad)
      end
    end

    test "mnemonic_from_entropy(<<0::127>>, :klingon) returns an error" do
      assert_raise MnemonistError,
                   "Invalid entropy value with 127 bits and language :klingon.",
                   fn ->
                     mnemonic_from_entropy!(@entropy_bad, :klingon)
                   end
    end
  end

  describe "mnemonic_to_seed/3" do
    test ~s{mnemonic_to_seed(abandon_about, "TREZOR") produces a valid seed} do
      assert {:ok, @seed_english_trezor} == mnemonic_to_seed(@mnemonic_abandon_about, "TREZOR")
    end

    test "mnemonic_to_seed(abandon_about) produces a valid seed" do
      assert {:ok, @seed_english_default} == mnemonic_to_seed(@mnemonic_abandon_about)
    end

    test ~s{mnemonic_to_seed(abaco_abierto, "TREZOR", "spanish") produces a valid seed} do
      assert {:ok, @seed_spanish_trezor} ==
               mnemonic_to_seed(@mnemonic_abaco_abierto, "TREZOR", "spanish")
    end

    test ~s{mnemonic_to_seed(abaco_abierto, :spanish) produces a valid seed} do
      assert {:ok, @seed_spanish_default} == mnemonic_to_seed(@mnemonic_abaco_abierto, :spanish)
    end

    test ~s{mnemonic_to_seed(abaco_abierto, "spanish") returns an error} do
      assert {:error, "Invalid mnemonic word (\"ábaco\") for language :english."} ==
               mnemonic_to_seed(@mnemonic_abaco_abierto, "spanish")
    end

    test ~s{mnemonic_to_seed(:invalid) returns an error} do
      assert {:error, "Mnemonic must be a binary string."} == mnemonic_to_seed(:invalid)
    end

    test ~s{mnemonic_to_seed(abandon_about, :invalid) returns an error} do
      assert {:error, "Passphrase must be a binary string."} ==
               mnemonic_to_seed(@mnemonic_abandon_about, :invalid)
    end

    test ~s{mnemonic_to_seed(abandon_about, "valid", :klingon) returns an error} do
      assert {:error, "Invalid mnemonic language :klingon, must be one of:" <> _} =
               mnemonic_to_seed(@mnemonic_abandon_about, "valid", :klingon)
    end
  end

  describe "mnemonic_to_seed!/3" do
    test ~s{mnemonic_to_seed!(abandon_about, "TREZOR") produces a valid seed} do
      assert @seed_english_trezor == mnemonic_to_seed!(@mnemonic_abandon_about, "TREZOR")
    end

    test "mnemonic_to_seed!(abandon_about) produces a valid seed" do
      assert @seed_english_default == mnemonic_to_seed!(@mnemonic_abandon_about)
    end

    test ~s{mnemonic_to_seed!(abaco_abierto, "TREZOR", "spanish") produces a valid seed} do
      assert @seed_spanish_trezor == mnemonic_to_seed!(@mnemonic_abaco_abierto, "TREZOR", "spanish")
    end

    test ~s{mnemonic_to_seed!(abaco_abierto, :spanish) produces a valid seed} do
      assert @seed_spanish_default == mnemonic_to_seed!(@mnemonic_abaco_abierto, :spanish)
    end

    test ~s{mnemonic_to_seed!(abaco_abierto, "spanish") returns an error} do
      assert_raise MnemonistError, "Invalid mnemonic word (\"ábaco\") for language :english.", fn ->
        mnemonic_to_seed!(@mnemonic_abaco_abierto, "spanish")
      end
    end

    test ~s{mnemonic_to_seed!(:invalid) returns an error} do
      assert_raise MnemonistError, "Mnemonic must be a binary string.", fn ->
        mnemonic_to_seed!(:invalid)
      end
    end

    test ~s{mnemonic_to_seed!(abandon_about, :invalid) returns an error} do
      assert_raise MnemonistError, "Passphrase must be a binary string.", fn ->
        mnemonic_to_seed!(@mnemonic_abandon_about, :invalid)
      end
    end

    test ~s{mnemonic_to_seed!(abandon_about, "valid", :klingon) returns an error} do
      assert_raise MnemonistError, ~r/Invalid mnemonic language :klingon, must be one of:/, fn ->
        mnemonic_to_seed!(@mnemonic_abandon_about, "valid", :klingon)
      end
    end
  end

  describe "mnemonic_to_entropy/2" do
    test "mnemonic_to_entropy(abandon_about) returns <<0::128>>" do
      assert {:ok, @entropy_good} == mnemonic_to_entropy(@mnemonic_abandon_about)
    end

    test "mnemonic_to_entropy(abaco_abierto) returns an error" do
      assert {:error, "Invalid mnemonic word (\"ábaco\") for language :english."} ==
               mnemonic_to_entropy(@mnemonic_abaco_abierto)
    end

    test ~s{mnemonic_to_entropy(abaco_abierto, "spanish") returns <<0::128>>} do
      assert {:ok, @entropy_good} == mnemonic_to_entropy(@mnemonic_abaco_abierto, "spanish")
    end

    test ~s{mnemonic_to_entropy(:invalid) returns an error} do
      assert {:error, "Mnemonic must be a binary string."} == mnemonic_to_entropy(:invalid)
    end

    test ~s{mnemonic_to_entropy(abandon_about, :klingon) returns an error} do
      assert {:error, "Invalid mnemonic language :klingon, must be one of" <> _} =
               mnemonic_to_entropy(@mnemonic_abandon_about, :klingon)
    end
  end

  describe "mnemonic_to_entropy!/2" do
    test "mnemonic_to_entropy!(abandon_about) returns <<0::128>>" do
      assert @entropy_good == mnemonic_to_entropy!(@mnemonic_abandon_about)
    end

    test "mnemonic_to_entropy!(abaco_abierto) returns an error" do
      assert_raise MnemonistError, "Invalid mnemonic word (\"ábaco\") for language :english.", fn ->
        mnemonic_to_entropy!(@mnemonic_abaco_abierto)
      end
    end

    test ~s{mnemonic_to_entropy!(abaco_abierto, "spanish") returns <<0::128>>} do
      assert @entropy_good == mnemonic_to_entropy!(@mnemonic_abaco_abierto, "spanish")
    end

    test ~s{mnemonic_to_entropy!(:invalid) returns an error} do
      assert_raise MnemonistError, "Mnemonic must be a binary string.", fn ->
        mnemonic_to_entropy!(:invalid)
      end
    end

    test ~s{mnemonic_to_entropy!(abandon_about, :klingon) returns an error} do
      assert_raise MnemonistError, ~r/Invalid mnemonic language :klingon, must be one of/, fn ->
        mnemonic_to_entropy!(@mnemonic_abandon_about, :klingon)
      end
    end
  end

  describe "valid_mnemonic?/2" do
    test "is false when the mnemonic is too short" do
      refute valid_mnemonic?("sleep kitten")
      refute valid_mnemonic?("sleep kitten sleep kitten sleep kitten")
    end

    test "is false when the mnemonic is too long" do
      mnemonic =
        for(_i <- 1..753, into: "", do: "abandon ") <>
          "about end grace oxygen maze bright face loan ticket trial leg cruel lizard bread worry reject journey perfect chef section caught neither install industry"

      refute valid_mnemonic?(mnemonic)
    end

    test "is false (other cases)" do
      refute valid_mnemonic?(
               "turtle front uncle idea crush write shrug there lottery flower risky shell"
             )

      refute valid_mnemonic?(
               "sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten"
             )
    end
  end

  describe "fetch_mnemonic_word/2" do
    test ~s[fetch_mnemonic_word(0) -> {:ok, "abandon"}] do
      assert {:ok, "abandon"} == fetch_mnemonic_word(0)
    end

    test ~s[fetch_mnemonic_word(0, "spanish") -> {:ok, "ábaco"}] do
      assert {:ok, "ábaco"} == fetch_mnemonic_word(0, "spanish")
    end

    test "fetch_mnemonic_word(2048) returns an error" do
      assert {:error, "Invalid mnemonic index (2048) for language :english."} ==
               fetch_mnemonic_word(2048)
    end

    test "fetch_mnemonic_word(0, :klingon) returns an error" do
      assert {:error, "Invalid mnemonic language :klingon."} == fetch_mnemonic_word(0, :klingon)
    end
  end

  describe "fetch_mnemonic_word!/2" do
    test ~s{fetch_mnemonic_word!(0) -> "abandon"} do
      assert "abandon" == fetch_mnemonic_word!(0)
    end

    test ~s{fetch_mnemonic_word!(0, "spanish") -> "ábaco"} do
      assert "ábaco" == fetch_mnemonic_word!(0, "spanish")
    end

    test "fetch_mnemonic_word!(2048) raises an error" do
      assert_raise MnemonistError, "Invalid mnemonic index (2048) for language :english.", fn ->
        fetch_mnemonic_word!(2048)
      end
    end

    test "fetch_mnemonic_word!(0, :klingon) returns an error" do
      assert_raise MnemonistError, "Invalid mnemonic language :klingon.", fn ->
        fetch_mnemonic_word!(0, :klingon)
      end
    end
  end

  describe "fetch_mnemonic_index/2" do
    test ~s[fetch_mnemonic_index("abandon") -> {:ok, 0}] do
      assert {:ok, 0} == fetch_mnemonic_index("abandon")
    end

    test ~s[fetch_mnemonic_index("ábaco", "spanish") -> {:ok, 0}] do
      assert {:ok, 0} == fetch_mnemonic_index("ábaco", "spanish")
    end

    test ~s{fetch_mnemonic_index("ábaco") returns an error} do
      assert {:error, ~s{Invalid mnemonic word ("ábaco") for language :english.}} ==
               fetch_mnemonic_index("ábaco")
    end

    test ~s{fetch_mnemonic_index("abandon", :klingon) returns an error} do
      assert {:error, "Invalid mnemonic language :klingon."} ==
               fetch_mnemonic_index("abandon", :klingon)
    end
  end

  describe "fetch_mnemonic_index!/2" do
    test ~s{fetch_mnemonic_index!("abandon") -> 0} do
      assert 0 == fetch_mnemonic_index!("abandon")
    end

    test ~s{fetch_mnemonic_index!("ábaco", "spanish") -> 0} do
      assert 0 == fetch_mnemonic_index!("ábaco", "spanish")
    end

    test ~s{fetch_mnemonic_index!("ábaco") raises an error} do
      assert_raise MnemonistError, ~s{Invalid mnemonic word ("ábaco") for language :english.}, fn ->
        fetch_mnemonic_index!("ábaco")
      end
    end

    test ~s{fetch_mnemonic_index!("abandon", :klingon) returns an error} do
      assert_raise MnemonistError, "Invalid mnemonic language :klingon.", fn ->
        fetch_mnemonic_index!("abandon", :klingon)
      end
    end
  end

  describe "detect_mnemonic_language/1" do
    for language <- Mnemonist.__supported_languages() do
      mnemonic = mnemonic_from_entropy!(<<1::128>>, language)

      test "<<1::128> mnemonic for #{language} is detected correctly" do
        assert {:ok, unquote(language)} == detect_mnemonic_language(unquote(mnemonic))
      end
    end

    for language <- [:chinese_simplified, :chinese_traditional] do
      mnemonic = mnemonic_from_entropy!(<<0::128>>, language)

      test "<<0::128> mnemonic for #{language} is ambiguous" do
        assert {:error, :ambiguous, [:chinese_simplified, :chinese_traditional]} ==
                 detect_mnemonic_language(unquote(mnemonic))
      end
    end

    test "unknown mnemonic words result in an error" do
      assert {:error, :invalid, "xylophone"} ==
               detect_mnemonic_language(
                 "xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone about"
               )
    end

    test "invalid mnemonic" do
      assert {:error, "Invalid mnemonic word count 2."} == detect_mnemonic_language("sleep kitten")
    end
  end

  describe "detect_mnemonic_language!/1" do
    for language <- Mnemonist.__supported_languages() do
      mnemonic = mnemonic_from_entropy!(<<1::128>>, language)

      test "<<1::128> mnemonic for #{language} is detected correctly" do
        assert unquote(language) == detect_mnemonic_language!(unquote(mnemonic))
      end
    end

    for language <- [:chinese_simplified, :chinese_traditional] do
      mnemonic = mnemonic_from_entropy!(<<0::128>>, language)

      test "<<0::128> mnemonic for #{language} is ambiguous" do
        assert_raise MnemonistError,
                     "Mnemonic language ambiguous between [:chinese_simplified, :chinese_traditional]",
                     fn ->
                       detect_mnemonic_language!(unquote(mnemonic))
                     end
      end
    end

    test "unknown mnemonic words result in an error" do
      assert_raise MnemonistError, ~s{Mnemonic language unrecognized for "xylophone"}, fn ->
        detect_mnemonic_language!(
          "xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone xylophone about"
        )
      end
    end

    test "invalid mnemonic" do
      assert_raise MnemonistError, "Invalid mnemonic word count 2.", fn ->
        detect_mnemonic_language!("sleep kitten")
      end
    end
  end

  defp to_hd_master_key(seed, testnet? \\ false) do
    assert byte_size(seed) == 64

    <<master_key::binary-32, chain_code::binary-32>> =
      :crypto.mac(:hmac, :sha512, "Bitcoin seed", seed)

    # Serialization format can be found at: https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#serialization-format
    version =
      if testnet? do
        <<0x04, 0x35, 0x83, 0x94>>
      else
        <<0x04, 0x88, 0xAD, 0xE4>>
      end

    xprv =
      <<
        version::binary,
        # depth
        <<0::8>>,
        # fingerprint,
        <<0::32>>,
        # child index
        <<0::32>>,
        chain_code::binary,
        0::8,
        master_key::binary
      >>

    hashed = :crypto.hash(:sha256, :crypto.hash(:sha256, xprv))

    # Double hash using SHA256 and take 4 bytes as the checksum
    checksum = binary_part(hashed, 0, 4)

    b58encode(<<xprv::binary, checksum::binary>>)
  end

  @base58_alphabet ~c"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
                   |> Enum.with_index()
                   |> Map.new(fn {c, i} -> {i, c} end)

  # Refactored code segments from <https://github.com/keis/base58>
  defp b58encode(value) do
    value
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> Enum.reduce({1, 0}, fn c, {p, acc} -> {Bitwise.bsl(p, 8), acc + p * c} end)
    |> encode_as_b58()
  end

  defp encode_as_b58({_p, acc}) do
    acc
    |> encode_as_b58([])
    |> :binary.list_to_bin()
  end

  defp encode_as_b58(0, charlist), do: charlist

  defp encode_as_b58(acc, charlist) do
    {acc, idx} = {div(acc, 58), Integer.mod(acc, 58)}
    encode_as_b58(acc, [@base58_alphabet[idx] | charlist])
  end
end
