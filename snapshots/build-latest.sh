#!/usr/bin/env bash

set -euo pipefail

latest=$(ls -1 cardano-*.yaml | sort -n -t. -k1 -k2 -k3 | tail -1)

if [ -n "${1:-}" ]; then
  latest="$1"
fi

echo "+++ Building $latest"

# Set up a dummy stack project.
# Note that when building a new snapshot you may need to remove
# the old one from ~/.stack/snapshots - to avoid linker errors, and
# also remove .stack-work.
rm -rf stack.yaml.lock
cat << EOF > stack.yaml
resolver: $latest
flags:
  cardano-crypto-praos:
    external-libsodium-vrf: false
nix:
  shell-file: ../shell.nix
EOF
cabal init --minimal --lib --non-interactive --dependency cardano-node --overwrite --package-name test-snapshot-build

# Build the cardano-node package.
# It doesn't test that _everything_ builds, but it does build a highly
# relevant subset.
exec stack build --nix --fast cardano-node
