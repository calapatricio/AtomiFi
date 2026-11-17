#!/bin/bash
# Prints the lines that matter from the failed jobs of the latest CI run of
# a branch: analyzer messages, formatter changes and failed expectations.
# usage: tool/failures.sh <branch>
set -u
repo=calapatricio/atomifi
id=$(gh run list --repo "$repo" --branch "$1" --limit 1 --json databaseId -q '.[0].databaseId')
gh run view "$id" --repo "$repo" --log-failed 2>/dev/null | cut -f1,3- \
  | sed -E 's/[0-9T:.-]+Z //' \
  | grep -v '✅' \
  | grep -E "❌|error|warning|info •|info -|Formatted |Because|Expected|Actual|Which|The following|\[E\]|test/.*\.dart" \
  | head -80
