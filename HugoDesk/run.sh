#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p .build-cache .clang-cache
export CLANG_MODULE_CACHE_PATH="$PWD/.clang-cache"

swift run
