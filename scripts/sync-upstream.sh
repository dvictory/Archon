#!/usr/bin/env bash
# Sync with upstream coleam00/Archon while keeping your local work intact.
#
# Layout assumed:
#   origin   -> your fork (e.g. dvictory/Archon)
#   upstream -> coleam00/Archon
#   dev      -> read-only mirror of upstream/dev (never commit here)
#   my-dev   -> your working branch, rebased onto dev on each sync
#
# Usage:
#   bun run sync-upstream              # uses WORK_BRANCH=my-dev
#   WORK_BRANCH=feature-x ./scripts/sync-upstream.sh
set -euo pipefail

WORK_BRANCH="${WORK_BRANCH:-my-dev}"
TRACKED_BRANCH="${TRACKED_BRANCH:-dev}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"

say() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\n\033[1;31mfatal:\033[0m %s\n' "$*" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repo"
git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1 || die "no '$UPSTREAM_REMOTE' remote configured (expected coleam00/Archon)"
git remote get-url "$ORIGIN_REMOTE" >/dev/null 2>&1 || die "no '$ORIGIN_REMOTE' remote configured (expected your fork)"
git show-ref --verify --quiet "refs/heads/$WORK_BRANCH" || die "work branch '$WORK_BRANCH' does not exist locally"

if ! git diff-index --quiet HEAD -- || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  die "uncommitted or untracked changes present — commit, stash, or clean before syncing"
fi

start_branch="$(git rev-parse --abbrev-ref HEAD)"
cleanup() {
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "$start_branch" ]; then
    git checkout "$start_branch" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

say "Fetching from $UPSTREAM_REMOTE"
git fetch "$UPSTREAM_REMOTE"

say "Fast-forwarding $TRACKED_BRANCH to $UPSTREAM_REMOTE/$TRACKED_BRANCH"
git checkout "$TRACKED_BRANCH"
git pull --ff-only "$UPSTREAM_REMOTE" "$TRACKED_BRANCH"

say "Pushing $TRACKED_BRANCH to $ORIGIN_REMOTE"
git push "$ORIGIN_REMOTE" "$TRACKED_BRANCH"

say "Rebasing $WORK_BRANCH onto $TRACKED_BRANCH"
git checkout "$WORK_BRANCH"
if ! git rebase "$TRACKED_BRANCH"; then
  cat <<EOF

Rebase stopped with conflicts. Resolve them, then run:
  git add <files>
  git rebase --continue
  git push --force-with-lease $ORIGIN_REMOTE $WORK_BRANCH

Or to abort:
  git rebase --abort

EOF
  trap - EXIT
  exit 1
fi

say "Pushing $WORK_BRANCH to $ORIGIN_REMOTE (force-with-lease)"
git push --force-with-lease "$ORIGIN_REMOTE" "$WORK_BRANCH"

say "Sync complete. $WORK_BRANCH is now rebased onto latest $UPSTREAM_REMOTE/$TRACKED_BRANCH."
