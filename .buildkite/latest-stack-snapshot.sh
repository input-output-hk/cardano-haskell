#!/usr/bin/env bash

set -euo pipefail

echo "--- Setup"

mapfile -t latest < <( if [ -n "${1:-}" ]; then
    base_branch="$1"
    git fetch origin master 1>&2
    ( git diff "origin/${base_branch}..HEAD" --name-only --diff-filter=AM || true ) | grep '^snapshots/.*\.yaml$'
else
    ls -1 snapshots/cardano-*.yaml | sort -n -t. -k1 -k2 -k3 | tail -1
fi )

if [ ${#latest[@]} -eq 0 ]; then
    echo 'Stack snapshots unchanged, so skipping the build.'
    exit 0
fi

echo "Going to build: ${latest[@]}"

cd $(dirname $0)/../snapshots

echo "+++ Building nix-shell"
export NIX_PATH=$(nix-instantiate --read-write-mode --eval --json --expr '"nixpkgs=${(import ./shell.nix).pkgs.path}"' | tr -d '"')
compiler=$(nix-instantiate --read-write-mode --eval --json --expr '(import ./shell.nix).ghc.name' | tr -d '"')

echo '^^^ ---'
for resolver in "${latest[@]}"; do
    nix-shell --run "./build-snapshot.sh $(basename -s .yaml $resolver) $compiler"
done
