#!/usr/bin/env bash

set -euo pipefail

echo "--- Setup"

git submodule update --init

################################################################################
# Cabal config

cabal_args=()
if [ -n "${CABAL_STORE_DIR:-}" ]; then
  cabal_args+=("--store-dir=$CABAL_STORE_DIR")
fi

################################################################################
# Caching

restore_cache() {
  test -n "$cache_args" || exit 0
  echo "--- Restoring from cache..."
  cabal-cache sync-from-archive "${cache_args[@]}" || true
  echo
  echo "Finished restoring from cache"
}

save_cache() {
  echo "--- Saving to cache..."
  cabal-cache sync-to-archive "${cache_args[@]}" || true
  echo
  echo "Finished saving to cache"
}

cache_args=()
if [ -n "${CABAL_CACHE_ARCHIVE:-}" ]; then
  cache_args=(--threads=16 --archive-uri="$CABAL_CACHE_ARCHIVE")
  if [ -n "${CABAL_STORE_DIR:-}" ]; then
    cache_args+=("--store-path=$CABAL_STORE_DIR")
  fi
  trap "status=\$?; save_cache; exit \$status" EXIT
fi

################################################################################
# cardano-repo-tool

cd cardano-repo-tool
cabal update
restore_cache
echo "--- Building cardano-repo-tool"
cabal "${cabal_args[@]}" install --constraint="base16-bytestring<1.0.0.0" --installdir=../bin --overwrite-policy=always
cd ..

./bin/cardano-repo-tool --version

echo "+++ Updating repos"

./bin/cardano-repo-tool clone-repos

./bin/cardano-repo-tool repo-status

./bin/cardano-repo-tool update-repos

cabal update

restore_cache

################################################################################
# Build

echo "+++ Building cardano-haskell"
cabal "${cabal_args[@]}" build all -O0
