# Mnemonist Usage Rules

Mnemonist is a complete modern implementation of BIP-39 for Elixir. It supports
all BIP-39 language wordlists and provides functions for generating mnemonics,
converting between mnemonics and entropy, and deriving seeds.

## Core Principles

1. **Use specific functions** - Prefer `generate_mnemonic!/1` over manual
   entropy generation
2. **Choose the right variant** - `*!` raises, non-bang returns
   `{:ok, value} | {:error, reason}`
3. **Validate mnemonics** - Use `valid_mnemonic?/2` before processing
4. **Specify language when needed** - Default is `:english`, but 9 languages are
   supported

## Decision Guide: When to Use What

### Choose Your Function Variant

**Use `*!` functions when:**

- You want the application to crash immediately on error
- You're in a pipeline where exceptions are acceptable
- The operation should always succeed in your context

**Use non-bang functions when:**

- You want explicit error handling
- You need pattern matching on `{:ok, value}` or `{:error, reason}`
- Building conditional logic based on success/failure

### Mnemonic Generation

**Use `generate_mnemonic/0-2` when:**

- You want explicit error handling
- Returns `{:ok, mnemonic}` or `{:error, reason}`

**Use `generate_mnemonic!/0-2` when:**

- You want immediate crash on error
- Returns mnemonic string directly

```elixir
# Default: 24 words, English
{:ok, mnemonic} = Mnemonist.generate_mnemonic()
mnemonic = Mnemonist.generate_mnemonic!()

# Specify word count (12, 15, 18, 21, or 24)
{:ok, mnemonic} = Mnemonist.generate_mnemonic(12)

# Specify entropy bits (128, 160, 192, 224, or 256)
{:ok, mnemonic} = Mnemonist.generate_mnemonic(128)

# Specify language
{:ok, mnemonic} = Mnemonist.generate_mnemonic(:spanish)
{:ok, mnemonic} = Mnemonist.generate_mnemonic(12, :french)
```

### Entropy to Mnemonic

**Use `mnemonic_from_entropy/2` when:**

- You have existing entropy to convert
- You want explicit error handling

**Use `mnemonic_from_entropy!/2` when:**

- You trust the entropy is valid
- You want immediate crash on invalid entropy

```elixir
entropy = :crypto.strong_rand_bytes(16)  # 128 bits
{:ok, mnemonic} = Mnemonist.mnemonic_from_entropy(entropy)
mnemonic = Mnemonist.mnemonic_from_entropy!(entropy, :japanese)
```

### Mnemonic to Seed

**Use `mnemonic_to_seed/2-3` when:**

- Converting mnemonic to seed for key derivation
- You want explicit error handling

**Use `mnemonic_to_seed!/2-3` when:**

- You trust the mnemonic is valid
- You want immediate crash on invalid mnemonic

```elixir
# Without passphrase
{:ok, seed} = Mnemonist.mnemonic_to_seed(mnemonic)
seed = Mnemonist.mnemonic_to_seed!(mnemonic)

# With passphrase
{:ok, seed} = Mnemonist.mnemonic_to_seed(mnemonic, "my passphrase")
seed = Mnemonist.mnemonic_to_seed!(mnemonic, "my passphrase", :english)
```

### Mnemonic to Entropy

**Use `mnemonic_to_entropy/2` when:**

- Recovering entropy from mnemonic
- You want explicit error handling

**Use `mnemonic_to_entropy!/2` when:**

- You trust the mnemonic is valid
- You want immediate crash on invalid mnemonic

```elixir
{:ok, entropy} = Mnemonist.mnemonic_to_entropy(mnemonic)
entropy = Mnemonist.mnemonic_to_entropy!(mnemonic, :korean)
```

## Common Patterns

### Basic Mnemonic Generation

```elixir
# Generate 24-word English mnemonic
mnemonic = Mnemonist.generate_mnemonic!()

# Generate 12-word Spanish mnemonic
mnemonic = Mnemonist.generate_mnemonic!(12, :spanish)

# Generate with explicit error handling
case Mnemonist.generate_mnemonic(18, :french) do
  {:ok, mnemonic} -> IO.puts(mnemonic)
  {:error, reason} -> IO.puts("Error: #{reason}")
end
```

### Mnemonic to Seed Conversion

```elixir
# Basic conversion
mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
seed = Mnemonist.mnemonic_to_seed!(mnemonic)

# With passphrase for additional security
seed = Mnemonist.mnemonic_to_seed!(mnemonic, "my secure passphrase")

# With explicit error handling
case Mnemonist.mnemonic_to_seed(mnemonic, "passphrase") do
  {:ok, seed} -> derive_keys(seed)
  {:error, reason} -> handle_error(reason)
end
```

### Validation

```elixir
# Check if mnemonic is valid
if Mnemonist.valid_mnemonic?(mnemonic) do
  seed = Mnemonist.mnemonic_to_seed!(mnemonic)
else
  IO.puts("Invalid mnemonic")
end

# Validate with specific language
if Mnemonist.valid_mnemonic?(mnemonic, :italian) do
  process_mnemonic(mnemonic)
end
```

### Language Detection

```elixir
# Detect language from mnemonic
case Mnemonist.detect_mnemonic_language(mnemonic) do
  {:ok, language} -> IO.puts("Language: #{language}")
  {:error, :ambiguous, candidates} -> IO.puts("Ambiguous: #{inspect(candidates)}")
  {:error, :unrecognized, word} -> IO.puts("Unrecognized word: #{word}")
  {:error, reason} -> IO.puts("Error: #{reason}")
end

# Detect with crash on error
language = Mnemonist.detect_mnemonic_language!(mnemonic)
```

### Working with Wordlists

```elixir
# Fetch word by index
{:ok, word} = Mnemonist.fetch_mnemonic_word(0)  # "abandon"
word = Mnemonist.fetch_mnemonic_word!(42, :spanish)

# Fetch index by word
{:ok, index} = Mnemonist.fetch_mnemonic_index("abandon")
index = Mnemonist.fetch_mnemonic_index!("hola", :spanish)
```

### Custom Entropy

```elixir
# Generate mnemonic from custom entropy
entropy = :crypto.strong_rand_bytes(32)  # 256 bits
{:ok, mnemonic} = Mnemonist.mnemonic_from_entropy(entropy)

# Round-trip: mnemonic -> entropy -> mnemonic
original = Mnemonist.generate_mnemonic!()
entropy = Mnemonist.mnemonic_to_entropy!(original)
recovered = Mnemonist.mnemonic_from_entropy!(entropy)
^original = recovered  # Should match
```

## Supported Languages

Mnemonist supports 12 BIP-39 languages:

| Language            | Atom                   | String                  |
| ------------------- | ---------------------- | ----------------------- |
| Chinese Simplified  | `:chinese_simplified`  | `"chinese_simplified"`  |
| Chinese Traditional | `:chinese_traditional` | `"chinese_traditional"` |
| Czech               | `:czech`               | `"czech"`               |
| English (default)   | `:english`             | `"english"`             |
| French              | `:french`              | `"french"`              |
| Italian             | `:italian`             | `"italian"`             |
| Japanese            | `:japanese`            | `"japanese"`            |
| Korean              | `:korean`              | `"korean"`              |
| Portuguese          | `:portuguese`          | `"portuguese"`          |
| Russian             | `:russian`             | `"russian"`             |
| Spanish             | `:spanish`             | `"spanish"`             |
| Turkish             | `:turkish`             | `"turkish"`             |

Languages can be specified as atoms or strings. The default is `:english`.

## Valid Entropy and Mnemonic Lengths

| Entropy Bits | Mnemonic Words | Use Case                   |
| ------------ | -------------- | -------------------------- |
| 128          | 12             | Minimum security           |
| 160          | 15             | Enhanced security          |
| 192          | 18             | High security              |
| 224          | 21             | Very high security         |
| 256          | 24             | Maximum security (default) |

## Function Reference

### Generation

- `generate_mnemonic/0-2` - Generate mnemonic, returns `{:ok, mnemonic}` or
  `{:error, reason}`
- `generate_mnemonic!/0-2` - Generate mnemonic, raises on error

### Conversion

- `mnemonic_from_entropy/2` - Convert entropy to mnemonic
- `mnemonic_from_entropy!/2` - Convert entropy to mnemonic, raises on error
- `mnemonic_to_entropy/2` - Convert mnemonic to entropy
- `mnemonic_to_entropy!/2` - Convert mnemonic to entropy, raises on error
- `mnemonic_to_seed/2-3` - Convert mnemonic to seed (with optional passphrase)
- `mnemonic_to_seed!/2-3` - Convert mnemonic to seed, raises on error

### Validation

- `valid_mnemonic?/2` - Check if mnemonic is valid

### Language Detection

- `detect_mnemonic_language/1` - Detect language from mnemonic
- `detect_mnemonic_language!/1` - Detect language, raises on error

### Wordlist Access

- `fetch_mnemonic_word/2` - Get word by index
- `fetch_mnemonic_word!/2` - Get word by index, raises on error
- `fetch_mnemonic_index/2` - Get index by word
- `fetch_mnemonic_index!/2` - Get index by word, raises on error

## Common Gotchas

1. **Entropy Bits and Word Count** - Entropy must be 128, 160, 192, 224, or 256
   bits, corresponding to 12, 15, 18, 21, or 24 words respectively. Other bit
   sizes or word counts will return an error.

2. **Checksum Validation** - `mnemonic_to_entropy/2` validates the checksum. An
   invalid checksum returns an error.

3. **Language Ambiguity** - Some mnemonic words exist in multiple languages. Use
   `detect_mnemonic_language/1` to check for ambiguity.

4. **Normalization** - Mnemonics and passphrases are normalized using NFKD
   Unicode normalization and converted to lowercase. "caf\u00E9" (U+00E9) and
   "cafe\u0301" (U+0301) normalize to the same result. Excess whitespace is
   ignored, whether leading, trailing or between mnemonic words. Japanese
   mnemonics use ideographic space (U+3000).

5. **Seed Derivation** - Seeds are always 512 bits (64 bytes) regardless of
   mnemonic length.

## BIP-39 Compliance

Mnemonist is fully compliant with BIP-39:

- Uses PBKDF2-HMAC-SHA512 with 2048 iterations for seed derivation
- Supports all 12 official BIP-39 wordlists
- Validates checksums according to BIP-39 specification
- Normalizes input using NFKD Unicode normalization
- Tested against Trezor test vectors

## Resources

- **[Hex Package](https://hex.pm/packages/mnemonist)** - Package on Hex.pm
- **[HexDocs](https://hexdocs.pm/mnemonist)** - Complete API documentation
- **[GitHub Repository](https://github.com/halostatue/mnemonist)** - Source code
  and issues
- **[BIP-39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)** -
  Official specification
- **[BIP-39 Wordlists](https://github.com/bitcoin/bips/blob/master/bip-0039/bip-0039-wordlists.md)** -
  Official wordlists

## Security Considerations

1. **Entropy Source** - Always use cryptographically secure random number
   generators (`:crypto.strong_rand_bytes/1`)

2. **Mnemonic Storage** - Store mnemonics securely. They provide full access to
   derived keys.

3. **Passphrase Protection** - Use a strong passphrase for additional security.
   The passphrase acts as a "25th word".

4. **Seed Handling** - Seeds should be treated as highly sensitive. Never log or
   transmit seeds in plaintext.

5. **Language Selection** - Ensure the correct language is used when recovering
   mnemonics. Use `detect_mnemonic_language/1` if uncertain.

6. **Validation** - Always validate mnemonics with `valid_mnemonic?/2` before
   use, especially when accepting user input.
