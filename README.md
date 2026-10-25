# Travispwingo Tap

Homebrew formulae for [Plain](https://plain-lang.dev), a programming language written in everyday English.

## How do I install Plain?

```sh
brew install travispwingo/tap/plain
```

That one command adds this tap, trusts only the `plain` formula from it, and installs Plain. It works with Homebrew on a Mac and on Linux. Then check it:

```sh
plain --version
```

Or, in a `brew bundle` `Brewfile`:

```ruby
tap "travispwingo/tap"
brew "travispwingo/tap/plain", trusted: true
```

If you'd rather tap first and then use the short name, Homebrew asks you to trust the formula once:

```sh
brew tap travispwingo/tap
brew trust --formula travispwingo/tap/plain
brew install plain
```

## Update or remove Plain

```sh
brew upgrade plain
brew uninstall plain
```

## No Homebrew?

Windows, Linux and Macs without Homebrew can install Plain from PyPI with [uv](https://docs.astral.sh/uv/): `uv tool install plainlang`. See [plain-lang.dev/install](https://plain-lang.dev/install/) for every step.

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

Plain's own source, issues and lessons: [github.com/travispwingo/plain-lang](https://github.com/travispwingo/plain-lang) and [plain-lang.dev](https://plain-lang.dev).

Maintainer notes for releases are in [RELEASING.md](RELEASING.md).
