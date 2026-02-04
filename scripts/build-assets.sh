#!/usr/bin/env bash
set -euxo pipefail

if [ -z "${PWD:-}" ]; then
  echo "Missing working directory"; exit 1
fi
if [ -z "${TMPDIR:-}" ]; then
  echo "Missing TMPDIR"; exit 1
fi

export PROJECT_ROOT="$PWD"

pushd frontend

echo "TMPDIR=$TMPDIR"

# Step 1: Compile Tailwind CSS
tailwindcss -c tailwind.config.js \
  -i $PROJECT_ROOT/frontend/styles/tailwind.css \
  -o $PROJECT_ROOT/frontend/public/style.css

# Step 2: Compile WASM
export CARGO_TARGET_DIR="$PWD/target"

echo "Running cargo build manually for wasm32-unknown-unknown target:"
cargo build --release --lib --target wasm32-unknown-unknown --verbose

echo "Running wasm-bindgen manually:"
mkdir -p "$TMPDIR/pkg"
wasm-bindgen target/wasm32-unknown-unknown/release/frontend.wasm --target web --out-dir "$TMPDIR/pkg"

# Step 3: Bundle frontend JavaScript
echo "Running esbuild to create bundle.js:"
mkdir -p "$TMPDIR/dist"

esbuild src/main.js \
  --bundle \
  --outfile="$TMPDIR/dist/bundle.js" \
  --format=esm \
  --external:./pkg/frontend.js

popd

# Step 4: Assemble dist/
mkdir -p dist

echo "Copying index.html..."
cp frontend/public/index.html dist/

echo "Copying style.css..."
cp frontend/public/style.css dist/

echo "Copying bundle.js..."
cp "$TMPDIR/dist/bundle.js" dist/

echo "Copying wasm/pkg artifacts..."
cp -r "$TMPDIR/pkg" dist/pkg

echo "Assets build complete."
