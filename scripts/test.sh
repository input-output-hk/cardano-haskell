#!/bin/sh

set -xe

git submodule update --init

nix-shell \
--show-trace \
--run '
      unset CABAL_CONFIG
      cardano-repo-tool clone-repos
      cabal new-update
      cabal new-configure --with-compiler ghc-8.6.5 -O0
      cabal new-build all
      '
## NOTE:  we could've used the decoupled shell definition from below,
##        but we choose not to, to test the shell.nix we have.
# --packages 'with (import ./cardano-repo-tool {}); [ cardano-repo-tool pkgs.cabal-install pkgs.haskell.compiler ]' \
