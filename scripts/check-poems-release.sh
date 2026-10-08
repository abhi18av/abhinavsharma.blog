#!/usr/bin/env bash
# Zenodo records are permanent. Refuse to release if anything unpublished would be archived.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
n=$(ls poems/*/index.qmd 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -gt 0 ] || { echo "no poems to release"; exit 1; }
if drafts=$(grep -lE '^draft:[[:space:]]*true' poems/*/index.qmd); then
  echo "DRAFT poems would be archived permanently:"; echo "$drafts"; fail=1
fi
[ "$(git branch --show-current)" = main ] || { echo "not on main"; fail=1; }
[ -z "$(git status --porcelain)" ] || { echo "working tree not clean"; fail=1; }
git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "main not in sync with origin"; fail=1; }
exit $fail
