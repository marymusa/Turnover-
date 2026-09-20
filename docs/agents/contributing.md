# Contributing: fork workflow

`maria.munoz@sngular.com` (GitHub `marymusa`) has read-only access to `lukegothic/Turnover-`. Changes go
through a personal fork, `marymusa/Turnover-`, already created and configured as a remote:

- `upstream` → `lukegothic/Turnover-` (read-only, source of truth)
- `origin` → `marymusa/Turnover-` (write access, push branches here)

`main` tracks `upstream/main`.

## Conventions

- Never commit directly on `main`. For each change:
  1. `git checkout main && git pull` — sync with `upstream`.
  2. `git checkout -b <branch-name>` — one branch per change.
  3. Commit on the branch.
  4. `git push origin <branch-name>` — pushes to the fork.
  5. `gh pr create --repo lukegothic/Turnover- --head marymusa:<branch-name> --base main` — opens the PR against upstream.
- The fork already exists; there's no need to fork again or ask before using it.
- Still confirm with the user before the actual `push` and before opening the PR — those are visible, shared-state actions — but no need to re-ask about the fork/branch setup itself.
