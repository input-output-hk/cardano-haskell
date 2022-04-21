{ sources ? import ./nix/sources.nix {}
, pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib
, iohkLib ? import sources.iohk-nix {}
, compiler ? "ghc8107"
, haskell ? pkgs.haskell
, haskellNix ? import
, haskellPackages0 ? if compiler == null then pkgs.haskellPackages else haskell.packages.${compiler}
, libsodium ? pkgs.libsodium
, withIde ? true
}: let
  haskellPackages = haskellPackages0.extend (self: super: {
    nix-archive = self.callCabal2nix "nix-archive" sources.nix-archive {};
    cardano-repo-tool = self.callCabal2nix "cardano-repo-tool" ./cardano-repo-tool {};
  });
  libsodium-vrf = libsodium.overrideAttrs (oldAttrs: {
    name = "libsodium-1.0.18-vrf";
    src = pkgs.fetchFromGitHub {
      owner = "input-output-hk";
      repo = "libsodium";
      # branch tdammers/rebased-vrf
      rev = "66f017f16633f2060db25e17c170c2afa0f2a8a1";
      sha256 = "12g2wz3gyi69d87nipzqnq4xc6nky3xbmi2i2pb2hflddq8ck72f";
    };
    nativeBuildInputs = [ pkgs.autoreconfHook ];
    configureFlags = "--enable-static";
  });

in pkgs.mkShell {
  buildInputs = [
    haskellPackages.cabal-install # optional

    haskellPackages.ghc
    haskellPackages.cardano-repo-tool
    libsodium-vrf

    pkgs.lmdb
    pkgs.systemd

    pkgs.pkg-config
    pkgs.secp256k1
    pkgs.bzip2
    pkgs.lzma
    pkgs.ncurses
    pkgs.openssl
    pkgs.pcre
    pkgs.postgresql
    pkgs.zlib
  ] ++ lib.optional (pkgs.stdenv.hostPlatform.libc == "glibc") [
    pkgs.glibcLocales
  ] ++ lib.optional withIde [
    haskellPackages.haskell-language-server
  ];
}
