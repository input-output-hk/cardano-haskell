{ pkgs ? import <nixpkgs> {}
, compiler ? "ghc865"
}:

with pkgs;

mkShell rec {
  name = "cardano-haskell-env";
  meta.platforms = lib.platforms.unix;

  ghc = haskell.compiler.${compiler};

  tools = [
    ghc
    cabal-install
    nix
    pkgconfig
  ] ++ lib.optional (!stdenv.isDarwin) git;

  libs = [
    bzip2
    libsodium  # note: is upstream release version
    lzma
    ncurses
    openssl
    pcre
    postgresql
    zlib
  ]
  ++ lib.optional (stdenv.hostPlatform.libc == "glibc") glibcLocales
  ++ lib.optional stdenv.isLinux systemd.dev
  ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    Cocoa CoreServices libcxx libiconv
  ]);

  buildInputs = tools ++ libs;

  # Ensure that libz.so and other libraries are available to TH splices.
  LD_LIBRARY_PATH = lib.makeLibraryPath libs;

  # Force a UTF-8 locale because many Haskell programs and tests
  # assume this.
  LANG = "en_US.UTF-8";

  # Make the shell suitable for the stack nix integration
  # <nixpkgs/pkgs/development/haskell-modules/generic-stack-builder.nix>
  GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  STACK_IN_NIX_SHELL = "true";
}
