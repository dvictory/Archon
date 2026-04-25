# Staying in sync with upstream `coleam00/Archon`

This fork tracks the open-source [`coleam00/Archon`](https://github.com/coleam00/Archon)
project. Your local customizations live alongside upstream code without
fighting it on every pull.

## Repo layout

| Remote     | URL                                  | Purpose                     |
| ---------- | ------------------------------------ | --------------------------- |
| `origin`   | `git@github.com:dvictory/Archon.git` | Your fork. You push here.   |
| `upstream` | `https://github.com/coleam00/Archon` | Source of truth. Read-only. |

| Branch                 | Role                                                                |
| ---------------------- | ------------------------------------------------------------------- |
| `dev`                  | **Read-only mirror** of `upstream/dev`. Never commit here directly. |
| `my-dev`               | Your working branch. All your code lives here.                      |
| `<feature>` (optional) | Short-lived branch off `my-dev` for isolated experiments.           |

## The sync flow — one command

```bash
bun run sync-upstream
```

That runs `scripts/sync-upstream.sh`, which does:

1. `git fetch upstream`
2. Fast-forward `dev` to `upstream/dev`, push `dev` to your fork.
3. Rebase `my-dev` onto `dev`, push with `--force-with-lease`.

The script aborts early if you have uncommitted or untracked changes —
commit, stash, or clean before syncing.

### When the rebase hits conflicts

The script stops and prints next steps:

```bash
# resolve conflicted files, then:
git add <files>
git rebase --continue
git push --force-with-lease origin my-dev

# or to bail out:
git rebase --abort
```

Resolve conflicts the same way as any other rebase. If you find yourself
hand-merging the same file repeatedly across syncs, that file probably
belongs in user scope — see the next section.

## Why this stays low-conflict: the override pattern

Archon resolves commands and workflows in this order:

1. Repo `.archon/commands/<name>.md` and `.archon/workflows/<name>.yaml`
   — **user scope**, you own these.
2. Bundled `.archon/commands/defaults/<name>.md` and
   `.archon/workflows/defaults/<name>.yaml` — **upstream owns these**.

Project-level files override defaults of the same name. So:

- **Always** put your customizations in `.archon/commands/` or
  `.archon/workflows/` (no `defaults/` segment).
- **Never** edit files inside `.archon/commands/defaults/` or
  `.archon/workflows/defaults/`. Those are upstream's territory and will
  conflict on every pull.
- Adding a genuinely new file? Same rule — drop it in user scope unless
  you intend to PR it upstream.

If upstream introduces a new default that you want to customize: copy it
to user scope, then edit your copy. The default file in `defaults/`
stays untouched.

## Day-to-day workflow

```bash
# Start on your work branch
git checkout my-dev

# Make changes, commit normally
git add ...
git commit -m "..."

# When you want upstream's latest:
bun run sync-upstream
```

For larger changes you want to keep isolated:

```bash
git checkout -b feature/my-thing my-dev
# ...work, commits...
git checkout my-dev
git merge --ff-only feature/my-thing      # or rebase, your preference
git branch -d feature/my-thing
```

## Customizing the sync target

Override defaults via env vars:

```bash
WORK_BRANCH=feature/my-thing bun run sync-upstream
TRACKED_BRANCH=main bun run sync-upstream
UPSTREAM_REMOTE=oss bun run sync-upstream
```

## Troubleshooting

| Problem                                                 | Fix                                                                                                  |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `fatal: no 'upstream' remote configured`                | `git remote add upstream https://github.com/coleam00/Archon`                                         |
| `fatal: work branch 'my-dev' does not exist locally`    | `git checkout -b my-dev dev`                                                                         |
| `Your local changes to the following files would be...` | Commit, stash, or revert before syncing — the script intentionally refuses to run with a dirty tree. |
| Rebase conflicts on the same file every sync            | That file is in upstream's territory. Move your customization to user scope (see override pattern).  |
| Want to undo a sync                                     | `git reflog` shows pre-rebase position; `git reset --hard <hash>` restores it.                       |

## Contributing back upstream

If a change you've made on `my-dev` would benefit everyone, open a PR
against `coleam00/Archon`:

```bash
git checkout -b contrib/my-fix dev          # branch off pristine upstream
git cherry-pick <hash>                      # bring just the relevant commits
git push -u origin contrib/my-fix
gh pr create --repo coleam00/Archon --base dev --head dvictory:contrib/my-fix
```
