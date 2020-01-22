let
  nixpkgs          = import ./default.nix;
  default-compiler = "ghc865";
  overrides        = import ./overrides.nix;
in
{ compiler       ? default-compiler
, system         ? builtins.currentSystem
, crossSystem    ? null
, config         ? {}
}:
let
  pkgs      = (nixpkgs {}).pkgs;
  ghcOrig   = pkgs.haskell.packages."${compiler}";
  ghc       = ghcOrig.override { overrides = overrides pkgs; };
  repo-tool = (import ../cardano-repo-tool {}).haskellPackages.cardano-repo-tool.components.exes.cardano-repo-tool;

  extras   = with pkgs; [
    ncurses
    openssl
    pkgconfig
    postgresql
    repo-tool
    systemd
    tmux
    zlib
    ghc.ghcid
    ghc.cabal-install
  ];
in {
  inherit ghc;

  shell     = ghc.shellFor {
    packages    = p: [p.vty];
    buildInputs = extras;
    withHoogle  = true;
  };
}
