#!/bin/bash
# Waits for the latest CI run of a branch and prints the result of each job.
# usage: tool/ci.sh <branch>
set -u
repo=calapatricio/atomifi
sleep 12
id=$(gh run list --repo "$repo" --branch "$1" --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch "$id" --repo "$repo" --interval 8 >/dev/null 2>&1
gh run view "$id" --repo "$repo" --json conclusion,displayTitle,jobs \
  -q '.displayTitle + " -> " + .conclusion + " | " + ([.jobs[] | .name + ":" + .conclusion] | join(", "))'
