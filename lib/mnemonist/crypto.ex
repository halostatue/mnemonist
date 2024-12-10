defmodule Mnemonist.Crypto do
  @moduledoc false

  @rounds 2048
  @length 64

  if Code.ensure_loaded?(:crypto) && function_exported?(:crypto, :pbkdf2_hmac, 5) do
    def pbkdf2(password, salt) do
      :crypto.pbkdf2_hmac(:sha512, password, salt, @rounds, @length)
    end
  else
    # This `pbkdf2/2` implementation is a variation of the version by Lanford Cai at
    # https://github.com/LanfordCai/mnemonic.
    #
    # This is only required for Elixir 1.16 running less than Erlang/OTP 24.2.
    def pbkdf2(password, salt) do
      init_block = :crypto.mac(:hmac, :sha512, password, <<salt::binary, 1::integer-size(32)>>)

      {<<result::binary-size(@length), _::binary>>, _} =
        Enum.reduce(1..(@rounds - 1), {init_block, init_block}, fn _i, {result, current_block} ->
          next_block = :crypto.mac(:hmac, :sha512, password, current_block)
          {:crypto.exor(result, next_block), next_block}
        end)

      result
    end
  end
end
