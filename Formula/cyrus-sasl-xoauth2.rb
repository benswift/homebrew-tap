class CyrusSaslXoauth2 < Formula
  desc "Cyrus SASL with the XOAUTH2 mechanism plugin (OAuth2 for mbsync/isync)"
  homepage "https://github.com/moriyoshi/cyrus-sasl-xoauth2"
  url "https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.28/cyrus-sasl-2.1.28.tar.gz"
  sha256 "7ccfc6abd01ed67c1a0924b353e526f1b766b21f42d4562ee635a8ebfc5bb38c"
  license "BSD-3-Clause-Attribution"

  # Private SASL build for the mail stack; deliberately not linked into the
  # prefix so it never shadows the system SASL or homebrew-core's cyrus-sasl.
  keg_only "it is a dedicated SASL build for isync and is referenced by opt_prefix"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "krb5"
  depends_on "openssl@3"

  uses_from_macos "libxcrypt"

  # XOAUTH2 SASL mechanism plugin (moriyoshi/cyrus-sasl-xoauth2), pinned to
  # master HEAD --- ahead of the v0.2 tag (2020) with a clang return-value fix
  # that newer toolchains otherwise treat as a hard error. Built into the same
  # keg as cyrus-sasl so it lands in libsasl2's own plugin dir; no SASL_PATH
  # wiring is needed for mbsync (or anything else) to find it.
  resource "xoauth2" do
    url "https://github.com/moriyoshi/cyrus-sasl-xoauth2/archive/36aabca54fd65c8fa7a707cb4936751599967904.tar.gz"
    sha256 "07d7a77c7c27f83923b830cbdd415602d680e85f4b8a2bdaf616322aea11b8dd"
  end

  def install
    # Build cyrus-sasl itself, mirroring homebrew-core's cyrus-sasl formula.
    system "./configure",
           "--disable-macos-framework",
           "--disable-dependency-tracking",
           "--disable-silent-rules",
           "--prefix=#{prefix}"
    system "make", "install"

    # Build the XOAUTH2 plugin against the cyrus-sasl we just installed. Its
    # Makefile.am installs libxoauth2.so into ${CYRUS_SASL_PREFIX}/lib/sasl2,
    # i.e. right beside the stock mechanisms in this keg.
    resource("xoauth2").stage do
      # Upstream's autogen.sh runs automake in --foreign mode; autoreconf does
      # not, so without this it fails on missing GNU files (AUTHORS/NEWS/...).
      inreplace "configure.ac", "AM_INIT_AUTOMAKE", "AM_INIT_AUTOMAKE([foreign])"
      mkdir "m4"
      system "autoreconf", "--force", "--install", "--verbose"
      system "./configure", "--with-cyrus-sasl=#{prefix}"
      system "make", "install"
    end
  end

  test do
    # The XOAUTH2 mechanism plugin is installed alongside the stock SASL
    # mechanisms in this keg's plugin dir (pluginviewer would verify it loads,
    # but it blocks on krb5/GSSAPI init under the sandboxed test runner).
    assert_path_exists lib/"sasl2/libxoauth2.so"
  end
end
