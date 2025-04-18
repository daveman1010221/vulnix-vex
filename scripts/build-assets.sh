#!/usr/bin/env bash
set -euo pipefail

# Ensure PROJECT_ROOT is set
if [ -z "${PROJECT_ROOT:-}" ]; then
  echo "Error: PROJECT_ROOT is not set. Please activate your dev environment with 'direnv allow'."
  exit 1
fi

# Move into the frontend directory
pushd "$PROJECT_ROOT/frontend"

# Build the frontend WebAssembly bundle
wasm-pack build --target web --out-dir ../dist/pkg

# Return to project root
popd

# Ensure dist directory exists
mkdir -p "$PROJECT_ROOT/dist"

# Copy static assets to dist
cp -r "$PROJECT_ROOT/frontend/public/"* "$PROJECT_ROOT/dist/"
