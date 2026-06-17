#!/usr/bin/env bash
set -euo pipefail

# fvm でピン留めした Flutter（.fvmrc）を使う。未導入なら案内して終了。
if ! command -v fvm >/dev/null 2>&1; then
  echo "fvm not found. Install: dart pub global activate fvm  (then: fvm install)" >&2
  exit 1
fi

fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
