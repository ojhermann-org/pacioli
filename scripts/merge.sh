#!/usr/bin/env bash
#
# Merge an owner-authored PR from the CLI as a ruleset bypass actor.
#
# `gh pr merge` can't do this: --admin overrides *classic* branch protection,
# not rulesets, and doesn't circumvent the merge queue; worse, `gh pr merge`
# refuses at pre-flight when you *have* ruleset bypass authority (cli/cli #8746,
# #13388). The raw REST merge endpoint DOES engage your bypass correctly — even
# with the merge queue + required review — so this script wraps that, then
# deletes the head branch and fast-forwards local main.
#
# Owner-run only: it bypasses the required owner review, so it is for merging
# YOUR OWN PRs (which you can't self-approve). External contributions go through
# the normal gate (your review -> queue). The auto-mode classifier blocks an
# agent from running this to self-merge, exactly as it blocks --admin.
#
# By default it refuses unless the PR's required checks are all green; pass
# --force to override (e.g. a docs-only emergency). Bypassing CI is the one
# thing this repo cares most about NOT doing casually.
#
# Usage: scripts/merge.sh <pr-number> [--force]
#
# Requires: gh (authenticated, with bypass authority), jq, git.
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' not found on PATH" >&2; exit 1; }; }
need gh
need jq
need git

FORCE=0
PR=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    [0-9]*) PR="$arg" ;;
    *) echo "usage: $0 <pr-number> [--force]" >&2; exit 2 ;;
  esac
done
[ -n "$PR" ] || { echo "usage: $0 <pr-number> [--force]" >&2; exit 2; }

REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

read -r STATE BRANCH CROSS < <(
  gh pr view "$PR" --json state,headRefName,isCrossRepository \
    --jq '[.state, .headRefName, .isCrossRepository] | @tsv'
)
[ "$STATE" = "OPEN" ] || { echo "error: PR #$PR is $STATE, not OPEN" >&2; exit 1; }

# Refuse to bypass CI unless --force: require all checks green first.
if [ "$FORCE" -ne 1 ]; then
  if ! gh pr checks "$PR" >/dev/null 2>&1; then
    echo "error: PR #$PR has failing or pending required checks — refusing." >&2
    echo "       re-run with --force to merge anyway (bypasses CI)." >&2
    exit 1
  fi
fi

echo "squash-merging PR #$PR on $REPO (ruleset bypass)"
gh api -X PUT "repos/$REPO/pulls/$PR/merge" -f merge_method=squash \
  --jq '"merged: \(.merged)  sha: \(.sha)"'

if [ "$CROSS" = "true" ]; then
  echo "head branch is on a fork — leaving it for the contributor to delete."
else
  echo "deleting branch '$BRANCH'"
  gh api -X DELETE "repos/$REPO/git/refs/heads/$BRANCH" >/dev/null 2>&1 \
    || echo "  (branch already gone)"
fi

# Fast-forward local main and prune stale tracking refs (the `git up` rhythm).
echo "syncing local repo"
git remote update -p >/dev/null 2>&1 || true
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  git merge --ff-only '@{u}' >/dev/null 2>&1 \
    || echo "  (local branch not fast-forwardable — check out main and run 'git up')"
fi
echo "done."
