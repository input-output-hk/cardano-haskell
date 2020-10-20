{ pkgs ? import <nixpkgs> {}
, compiler ? "ghc865"
# Import Haskell.nix master as of 2020-10-13, just for building cabal-cache.
, haskellNix ? import (builtins.fetchTarball {
    url = "https://github.com/input-output-hk/haskell.nix/archive/ab2f5a9b6d8cb1b18810194d9f4a6208710c358c.tar.gz";
    sha256 = "1j3zwrrmnigl44lqdiyywwhj5m0wb4v6bpl89v1wp31vxwyyf7rv";
  }) {}
}:

with pkgs;

let
  cabal-cache = (haskellNix.pkgs.haskell-nix.hackage-package {
    name = "cabal-cache";
    version = "1.0.2.1";
    compiler-nix-name = compiler;
    index-state = "2020-10-06T21:19:33Z";
    plan-sha256 = "02dw6bk4p6vydzs9js6nd7v9bjpv3pwf5ga77q1c9pr1v8ylbjsj";
  }).components.exes.cabal-cache;

in
mkShell rec {
  name = "cardano-haskell-env";
  meta.platforms = lib.platforms.unix;

  ghc = haskell.compiler.${compiler};

  tools = [
    ghc
    cabal-install
    pkgconfig
    cabal-cache
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
