#!/usr/bin/env bash

set -euo pipefail

git submodule update --init

cd cardano-repo-tool
cabal update
cabal install --constraint="base16-bytestring<1.0.0.0" --installdir=../bin --overwrite-policy=always
cd ..

./bin/cardano-repo-tool --version

./bin/cardano-repo-tool clone-repos

./bin/cardano-repo-tool repo-status

./bin/cardano-repo-tool update-repos

cabal update

cabal build all -O0
