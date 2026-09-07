#!/usr/bin/env bash
# Build the wasm module for a feature set and report bundle size. Run inside the devshell.
#   scripts/build.sh            # both spikes (default features)
#   scripts/build.sh ssh        # one spike alone, for the size delta
set -euo pipefail
cd "$(dirname "$0")/.."
feat="${1:-ssh,tls}"
cargo build --release --target wasm32-unknown-unknown --no-default-features --features "$feat"
wasm-bindgen --target web --no-typescript --out-dir www/pkg target/wasm32-unknown-unknown/release/wasm_spikes.wasm
wasm-opt -Os -o www/pkg/wasm_spikes_bg.wasm www/pkg/wasm_spikes_bg.wasm
raw=$(stat -c %s www/pkg/wasm_spikes_bg.wasm)
gz=$(gzip -9 -c www/pkg/wasm_spikes_bg.wasm | wc -c)
echo "features=$feat wasm raw=$raw gzip=$gz"
