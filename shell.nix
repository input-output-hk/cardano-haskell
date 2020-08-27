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
}
