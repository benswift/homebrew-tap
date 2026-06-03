class Isync < Formula
  desc "Synchronize a maildir with an IMAP server (SASL XOAUTH2 enabled)"
  homepage "https://isync.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/isync/isync/1.5.1/isync-1.5.1.tar.gz"
  sha256 "28cc90288036aa5b6f5307bfc7178a397799003b96f7fd6e4bd2478265bb22fa"
  license "GPL-2.0-or-later"

  # Unlike homebrew-core's isync, this build links cyrus-sasl (with the XOAUTH2
  # plugin) so mbsync can authenticate to Office365/Gmail via OAuth2.
  depends_on "benswift/tap/cyrus-sasl-xoauth2"
  depends_on "berkeley-db@5"
  depends_on "openssl@3"

  uses_from_macos "zlib"

  def install
    sasl = Formula["benswift/tap/cyrus-sasl-xoauth2"].opt_prefix
    system "./configure", *std_configure_args,
           "--disable-silent-rules",
           "--with-sasl=#{sasl}"
    system "make", "install"
  end

  test do
    system bin/"mbsync-get-cert", "duckduckgo.com:443"
  end
end
