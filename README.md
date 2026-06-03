# benswift/homebrew-tap

A small Homebrew tap providing an `isync` (mbsync) build with working OAuth2
(XOAUTH2) authentication --- the thing homebrew-core's `isync` can't do, because
it ships without SASL and there's no `cyrus-sasl-xoauth2` formula in core. This
is what you need to sync Office365 or Gmail over IMAP with `mbsync` on macOS.

## Formulae

- **`cyrus-sasl-xoauth2`** --- Cyrus SASL built from source with the
  [moriyoshi/cyrus-sasl-xoauth2](https://github.com/moriyoshi/cyrus-sasl-xoauth2)
  XOAUTH2 mechanism plugin bundled into the same keg, so the plugin lands in
  libsasl2's own plugin dir and no `SASL_PATH` wiring is needed. Keg-only, so it
  never shadows the system SASL or homebrew-core's `cyrus-sasl`.
- **`isync`** --- isync built `--with-sasl` against the formula above, so
  `mbsync` can negotiate the `XOAUTH2` mechanism.

## Install

```sh
brew install benswift/tap/isync
```

That pulls in `cyrus-sasl-xoauth2` automatically. To confirm the SASL build:

```sh
strings "$(brew --prefix)/bin/mbsync" | grep -o '+HAVE_LIBSASL'
```

You still supply and refresh the OAuth2 tokens yourself (e.g. via
`mutt_oauth2.py`) and set `AuthMech XOAUTH2` in your `.mbsyncrc`.

## Why this exists

homebrew-core's `isync` is compiled without SASL and core has no
`cyrus-sasl-xoauth2`, so OAuth2 IMAP doesn't work out of the box --- see
[Homebrew discussion #6520](https://github.com/orgs/Homebrew/discussions/6520).
Other distros (Arch, Alpine, FreeBSD, MacPorts) package the plugin; this tap is
a macOS stop-gap until core does.

Versions are pinned for reproducibility: isync 1.5.1, cyrus-sasl 2.1.28, and the
xoauth2 plugin at master HEAD (`36aabca`, ahead of the v0.2 tag with a clang
return-value fix that newer toolchains treat as a hard error).
