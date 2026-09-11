#!/usr/bin/env bash
set -euo pipefail
# Generate incompressible-looking deterministic files locally for throughput tests.
# Usage: ./generate-transfer-files.sh [output-dir]
OUTDIR="${1:-.}"
mkdir -p "$OUTDIR"
make_file() {
  local bytes="$1"; local path="$2"
  echo "Generating $path ($bytes bytes)..."
  if command -v openssl >/dev/null 2>&1; then
    set +o pipefail
    openssl enc -aes-256-ctr -pbkdf2 -pass pass:SJKTRM2026 -nosalt </dev/zero 2>/dev/null | head -c "$bytes" > "$path"
    set -o pipefail
  else
    echo "openssl not found; fallback to /dev/urandom (slower)."
    head -c "$bytes" /dev/urandom > "$path"
  fi
  ls -lh "$path"
  sha256sum "$path"
}
make_file 524288000  "$OUTDIR/uji-transfer-500MiB.bin"
make_file 2147483648 "$OUTDIR/uji-transfer-2GiB.bin"
echo "Done. Keep these files local; do not upload them back to LMS unless needed."
