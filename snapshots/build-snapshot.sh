#!/usr/bin/env bash

set -euo pipefail

if [ -n "${1:-}" ]; then
  resolver="$1"
else
  >&2 echo "usage: $0 YAML [COMPILER]"
  exit 1
fi

if [ -n "${2:-}" ]; then
  compiler="$2"
  compiler_yaml="compiler: $compiler"
else
  compiler_yaml=""
fi

echo "+++ Building $resolver [${compiler:-compiler from snapshot}]"

# Set up a dummy stack project.
# Note that when building a new snapshot you may need to remove
# the old one from ~/.stack/snapshots - to avoid linker errors, and
# also remove .stack-work.
rm -rf stack.yaml.lock
cat << EOF > stack.yaml
resolver: $resolver
$compiler_yaml
nix:
  # NIX_PATH=$NIX_PATH
  shell-file: shell.nix
EOF
cabal init --minimal --exe --non-interactive  --dependency base --dependency cardano-node --dependency cardano-cli --license Apache-2.0 --overwrite --package-name test-snapshot-build

echo
echo "# stack.yaml"
cat stack.yaml
echo

# Build the test package which depends on cardano-node.
# It doesn't test that _everything_ builds, but it does build a highly
# relevant subset.
exec stack build --nix --fast
