#!/bin/bash
# Applies to the working tree the changes the formatter made in the latest
# CI run of a branch. Commit and push afterwards.
# usage: tool/fmt.sh <branch>
set -u
repo=calapatricio/atomifi
cd "$(git rev-parse --show-toplevel)" || exit 1
patch=$(mktemp)
id=$(gh run list --repo "$repo" --branch "$1" --limit 1 --json databaseId -q '.[0].databaseId')
gh run view "$id" --repo "$repo" --log 2>/dev/null | grep "Check formatting" | cut -f3- \
  | sed -E 's/^[0-9T:.-]+Z //' | sed -n '/^diff --git/,$p' | grep -v '^##\[error\]' > "$patch"
if [ -s "$patch" ]; then
  git apply "$patch" && echo "applied formatter diff"
else
  echo "no formatter diff"
fi
