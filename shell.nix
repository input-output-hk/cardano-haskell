let
  crt = import ./cardano-repo-tool {};
  inherit (crt) pkgs nix-tools haskellPackages;
in
haskellPackages.shellFor rec {
  name = "cardano-haskell";
  packages = ps: with ps; [
    cardano-repo-tool
  ];
  nativeBuildInputs = buildInputs;
  buildInputs = (with haskellPackages; [
    cardano-repo-tool.components.exes.cardano-repo-tool
    (pkgs.haskell-nix.hackage-package {
       name = "ghcid"; version = "0.8.1"; }).components.exes.ghcid
    (pkgs.haskell-nix.hackage-package {
       name = "hlint"; version = "2.2.7"; }).components.exes.hlint
    (pkgs.haskell-nix.hackage-package {
       name = "cabal-install"; version = "3.0.0.0"; modules = [{reinstallableLibGhc = true;}]; }).components.exes.cabal
  ]) ++
  (with pkgs; [
    ncurses
    openssl
    pkgconfig
    postgresql
    systemd
    tmux
    zlib
  ]);
  shellHook = ''
  alias repo=cardano-repo-tool
  cat << EOF
  [37mRepo/hash management ('repo' aliased to 'cardano-repo-tool')[0m:

    [34mrepo clone-repos[0m            initial setup

    [34mrepo update-repos[0m           git checkout master && git pull --rebase
    [34mrepo update-repo -r REPO[0m

    [34mrepo update-hashes[0m          sub git hashes -> all sub cabal.project/stack.yaml
    [34mrepo update-hashes -r REPO[0m  sub git hash   -> sub cabal.project/stack.yaml

    [34mrepo update-cabal-project[0m   ./stack.yaml -hashes-> ./cabal.project
    [34mrepo update-stack-yaml[0m      ./cabal.project -hashes-> ./stack.yaml

  [37mBuilding ('cabal' sourced from 'cardano-repo-tool' repo)[0m:

    [34mcabal update[0m                get a recent copy of the hackage package index

    [34mcabal new-configure --with-compiler ghc-8.6.5 -O0 [--enable-profiling][0m
                                set up desired configuration (in a sub repo)

    [34mcabal new-build all -j4 --keep-going[0m
                                build everything, in parallel, ignoring failures
  EOF
  '';
}
