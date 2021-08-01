{ pkgs ? import (builtins.fetchTarball "https://nixos.org/channels/nixos-20.09/nixexprs.tar.xz") {}
, compiler ? "ghc8104"
# Import Haskell.nix master as of 2021-04-01,
# for building cardano-repo-tool and cabal-cache.
, haskellNix ? import (builtins.fetchTarball {
    url = "https://github.com/input-output-hk/haskell.nix/archive/e7961eee7bbaaa195b3255258f40d5536574eb74.tar.gz";
    sha256 = "0ils54jldagmgn3c1s7994s9gwv5mz5l9lpsn7c9islhhmx2wlzb";
  }) {}
, withRepoTools ? true
# Also import 21.05 branch to get a stack/nix-shell bugfix
, pkgs-2105 ? import (builtins.fetchTarball "https://nixos.org/channels/nixos-21.05/nixexprs.tar.xz") {}
}:

with pkgs;

let
  inherit ((haskellNix.pkgs.haskell-nix.project {
    src =
      assert (pkgs.lib.assertMsg (builtins.pathExists ./cardano-repo-tool/cabal.project) "Missing git submodule - run git submodule update --init");
      ./cardano-repo-tool;
    projectFileName = "cabal.project";
    compiler-nix-name = compiler;
    sha256map."https://github.com/input-output-hk/nix-archive"."7dcf21b2af54d0ab267f127b6bd8fa0b31cfa49d" = "0mhw896nfqbd2iwibzymydjlb3yivi9gm0v2g1nrjfdll4f7d8ly";
  }).hsPkgs.cardano-repo-tool.components.exes) cardano-repo-tool;

  inherit ((haskellNix.pkgs.haskell-nix.hackage-package {
    name = "cabal-cache";
    version = "1.0.3.0";
    compiler-nix-name = compiler;
    index-state = "2021-04-01T00:00:00Z";
    # plan-sha256 = "02dw6bk4p6vydzs9js6nd7v9bjpv3pwf5ga77q1c9pr1v8ylbjsj";
  }).components.exes) cabal-cache;

in
mkShell rec {
  name = "cardano-haskell-env";
  meta.platforms = lib.platforms.unix;

  ghc = haskell.compiler.${compiler};

  tools = [
    ghc
    cabal-install
    pkgs-2105.stack
    nix
    pkgconfig
  ] ++ lib.optionals withRepoTools [
    cardano-repo-tool
    cabal-cache
  ] ++ lib.optional (!stdenv.isDarwin) git;

  libs = [
    bzip2
    libsodium-vrf
    lzma
    ncurses
    openssl
    pcre
    postgresql
    zlib
  ]
  ++ lib.optional (stdenv.hostPlatform.libc == "glibc") glibcLocales
  ++ lib.optional stdenv.isLinux systemd
  ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    Cocoa CoreServices libcxx libiconv
  ]);

  libsodium-vrf = libsodium.overrideAttrs (oldAttrs: {
    name = "libsodium-1.0.18-vrf";
    src = fetchFromGitHub {
      owner = "input-output-hk";
      repo = "libsodium";
      # branch tdammers/rebased-vrf
      rev = "66f017f16633f2060db25e17c170c2afa0f2a8a1";
      sha256 = "12g2wz3gyi69d87nipzqnq4xc6nky3xbmi2i2pb2hflddq8ck72f";
    };
    nativeBuildInputs = [ autoreconfHook ];
    configureFlags = "--enable-static";
  });

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

  passthru = { inherit pkgs; };
}
