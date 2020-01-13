let
  crt = import ./cardano-repo-tool {};
  inherit (crt) pkgs nix-tools;
in
nix-tools._raw.shellFor {
  packages    = ps: with ps; [ cardano-repo-tool ];
  buildInputs = (with nix-tools._raw; [
    cabal-install.components.exes.cabal
    cardano-repo-tool.components.exes.cardano-repo-tool
    ghcid.components.exes.ghcid
  ]) ++
  (with nix-tools._raw._config._module.args.pkgs; [
    tmux
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
