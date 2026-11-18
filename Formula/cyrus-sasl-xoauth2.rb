class CyrusSaslXoauth2 < Formula
  desc "XOAUTH2 mechanism plugin for Cyrus SASL"
  homepage "https://github.com/moriyoshi/cyrus-sasl-xoauth2"
  url "https://github.com/moriyoshi/cyrus-sasl-xoauth2/archive/refs/tags/v0.2.tar.gz"
  sha256 "a62c26566098100d30aa254e4c1aa4309876b470f139e1019bb9032b6e2ee943"
  license "MIT"
  # This tap's earlier cyrus-sasl-xoauth2 was a whole Cyrus SASL build versioned
  # 2.1.28; the scheme bump lets existing installs upgrade to the plugin alone.
  version_scheme 1

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  uses_from_macos "cyrus-sasl"

  # Return the plugin init result; newer clang treats the missing return as an
  # error. Merged upstream after v0.2 (no release since).
  patch do
    url "https://github.com/moriyoshi/cyrus-sasl-xoauth2/commit/a0d05939c6da485a99cb92f628194f8b4e94a19d.patch?full_index=1"
    sha256 "37ebd052a1fbc59eb2dc1787bce7bebbe8edc553559d24185072197a6e6f3612"
  end

  def install
    sasl_prefix = OS.mac? ? MacOS.sdk_path/"usr" : formula_opt_prefix("cyrus-sasl")
    # Upstream's autogen.sh calls libtoolize (glibtoolize on macOS) and runs
    # automake in --foreign mode; autoreconf does neither by default.
    inreplace "configure.ac", "AM_INIT_AUTOMAKE", "AM_INIT_AUTOMAKE([foreign])"
    mkdir "m4"
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-static", "--with-cyrus-sasl=#{sasl_prefix}", *std_configure_args
    system "make", "install", "pkglibdir=#{lib}/sasl2"
  end

  def caveats
    system_plugins = OS.mac? ? "/usr/lib/sasl2" : "#{formula_opt_lib("cyrus-sasl")}/sasl2"
    <<~EOS
      Cyrus SASL loads plugins only from its search path. Set SASL_PATH wherever
      mbsync (or another SASL client) runs, including launchd or systemd jobs:
        export SASL_PATH="#{opt_lib}/sasl2:#{system_plugins}"
      This plugin's directory must come first: macOS's libsasl2 has its own
      XOAUTH2 mechanism, which mbsync cannot use.
    EOS
  end

  test do
    (testpath/"test.c").write <<~C
      #include <dlfcn.h>
      #include <stdio.h>
      #include <sasl/sasl.h>
      #include <sasl/saslplug.h>

      int main(int argc, char **argv) {
        void *plugin = dlopen(argv[1], RTLD_NOW);
        if (!plugin) {
          fprintf(stderr, "%s\\n", dlerror());
          return 1;
        }
        sasl_client_plug_init_t *init =
            (sasl_client_plug_init_t *)dlsym(plugin, "sasl_client_plug_init");
        int version, count;
        sasl_client_plug_t *plugins;
        if (!init || init(NULL, SASL_CLIENT_PLUG_VERSION, &version, &plugins, &count) != SASL_OK) {
          return 2;
        }
        printf("%s", plugins[0].mech_name);
        return 0;
      }
    C
    flags = ["-Wno-deprecated-declarations"]
    flags += ["-I#{formula_opt_include("cyrus-sasl")}", "-ldl"] if OS.linux?
    system ENV.cc, "test.c", "-o", "test", *flags
    assert_equal "XOAUTH2", shell_output("./test #{lib}/sasl2/libxoauth2.so")
  end
end
