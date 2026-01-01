# Mnemonist

- code :: https://github.com/halostatue/mnemonist
- issues :: https://github.com/halostatue/mnemonist/issues

> [**_mnemonist_**][wiktionary] `ˈniːmənɪst` (noun, plural **_mnemonists_**)
>
> Someone able to perform feats of memory, especially by using mnemonic
> techniques.

Mnemonist is a complete modern implementation of [BIP-39][bip39] for Elixir. It
supports all BIP-39 supported language wordlists and is validated against the
[Trezor test vectors][trezor-test-vectors].

Mnemonist is largely based on [LanfordCai/mnemonic][lc-mnemonic]'s
implementation, including the use of `m::crypto` for PBKDF2 implementation, but
has been influenced by the following projects:

- [aerosol/mnemo](https://github.com/aerosol/mnemo)
- [ayrat555/mnemoniac](https://github.com/ayrat555/mnemoniac)
- [izelnakri/mnemonic](https://github.com/izelnakri/mnemonic)
- [rudebono/bip39](https://github.com/rudebono/bip39)
- [trezor/python-mnemonic](https://github.com/trezor/python-mnemonic)

## Installation

Mnemonist can be installed by adding `mnemonist` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:mnemonist, "~> 1.3"}
  ]
end
```

Documentation, including usage, is found on [HexDocs][docs].

## Semantic Versioning

`Mnemonist` follows [Semantic Versioning 2.0][semver].

[bip39-wordlists]: https://github.com/bitcoin/bips/blob/master/bip-0039/bip-0039-wordlists.md
[bip39]: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
[docs]: https://hexdocs.pm/mnemonist
[lc-mnemonic]: https://github.com/LanfordCai/mnemonic
[semver]: https://semver.org/
[trezor-test-vectors]: https://github.com/trezor/python-mnemonic/blob/master/vectors.json
[wiktionary]: https://en.wiktionary.org/wiki/mnemonist
