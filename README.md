# benswift/homebrew-tap

A Homebrew tap for OAuth2 (XOAUTH2) IMAP with `mbsync` on macOS: the
[moriyoshi/cyrus-sasl-xoauth2](https://github.com/moriyoshi/cyrus-sasl-xoauth2)
SASL plugin, which homebrew-core doesn't package. With it, homebrew-core's own
bottled `isync` can sync Office365 or Gmail.

## Install

```sh
brew install isync benswift/tap/cyrus-sasl-xoauth2
```

Then point Cyrus SASL at the plugin, with its directory ahead of the system
plugins, wherever `mbsync` runs (your shell profile, and the
`EnvironmentVariables` of any launchd job that runs it):

```sh
export SASL_PATH="$(brew --prefix)/opt/cyrus-sasl-xoauth2/lib/sasl2:/usr/lib/sasl2"
```

The order matters. macOS's libsasl2 ships its own XOAUTH2 mechanism, which
`mbsync` can't use (it fails with `Unable to find a callback: 18948`); listing
this plugin's directory first makes SASL pick it instead.

You still supply and refresh the OAuth2 tokens yourself (e.g. via
`mutt_oauth2.py`) and set `AuthMech XOAUTH2` in your `.mbsyncrc`. To check it
works, `mbsync -V -l <channel>` should report
`Authenticating with SASL mechanism XOAUTH2...` and then list your folders.

## Upgrading from `benswift/tap/isync`

This tap used to ship its own `isync`, built against a bundled Cyrus SASL. That
is no longer needed: homebrew-core's `isync` bottle already links macOS's SASL,
and only the plugin was ever missing. `brew update` hands an installed `isync`
back to homebrew-core, and `brew upgrade` then pours core's bottle and replaces
the old bundled SASL with the plugin alone. Set `SASL_PATH` as above, or the
XOAUTH2 accounts will fail to authenticate.

## `brew services`

homebrew-core's `isync` has a service (`brew services start isync`), but the
launchd job it generates doesn't pass `SASL_PATH`. Running
`launchctl setenv SASL_PATH "..."` with the value above covers jobs launched
afterwards in your login session; it doesn't survive a reboot, so put it in a
login item or run `mbsync` from your own launchd job with `SASL_PATH` in its
`EnvironmentVariables`.

## Background

See
[Homebrew discussion #6520](https://github.com/orgs/Homebrew/discussions/6520).
Other distros (Arch, Alpine, FreeBSD, MacPorts) package the plugin; this tap is
a stop-gap until homebrew-core does.
