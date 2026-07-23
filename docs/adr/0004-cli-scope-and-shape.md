# 4. CLI scope and shape

- Status: Accepted
- Date: 2026-07-23
- Deciders: alex (captain)

## Context

v1's bugs were **bash doing systems work** (file-moves, symlinks, locks,
stdin-eating, `chsh`, PATH assumptions) — a category NixOS removes regardless of
whether a CLI exists. The captain still wants a CLI: a few known commands that
action things in a simple, predictable way. The risk to avoid is a CLI that
*re-implements what Nix already does* (v1 largely did, imperatively and buggily).

## Decision

Keep a small CLI. **The line: it wraps native Nix, it never re-implements it.**
Two kinds of command:

- **Thin front-door wrappers** over native Nix — a few lines that shell out,
  encoding hull's conventions:
  - `hull` (no args) — status: host, current generation, git-dirty, drift.
  - `hull switch` — `nixos-rebuild switch --flake .#<auto-host>`, after staging
    both git repos (hull + registry) so the flake sees them. *That staging is
    real glue Nix will not do for you.*
  - `hull diff` — build + closure diff (`nvd` / `nix store diff-closures`).
  - `hull rollback` — previous generation. `hull update` — `nix flake update`.
- **Imperative substance** — what Nix cannot do (it must never mint secrets or
  hit GitHub's API at eval time):
  - `hull account add | remove | list` — `ssh-keygen`, upload via `gh ssh-key
    add`, edit the registry `profile.nix`. (The lifecycle tool of ADR 0003.)
  - `hull doctor` — live verification: which account each key authenticates as,
    what identity / URL a repo really resolves to.

**Implementation:** the CLI is a Nix-built package — `pkgs.writeShellApplication`.
It stays **bash** (the tool's implementation language — independent of the
interactive login shell, which is zsh). `writeShellApplication` gives, for free:
shellcheck **at build time** (lint failure fails the build), declared runtime
deps (`gh`, `openssh`, `jq`, `nvd`…) **pinned onto PATH**, and safe flags
(`set -euo pipefail`). Non-trivial logic lives in pure `lib/` helpers shared with
the modules (e.g. the git-identity Generator). A fake-`$HOME` test harness covers
`account` / `doctor` from day one.

## Consequences

- The CLI is a lint-checked, dependency-pinned build artifact — not a loose
  script that hopes the machine is set up right. This kills v1's PATH / missing-dep
  / unchecked-script bug classes at build time.
- Commands stay few and predictable; new ones appear only when genuinely needed
  (pulled, not pushed) — no speculative `rollback`-that-was-never-run weight.
- The interactive shell (zsh) and the CLI's implementation language (bash) are
  unrelated; choosing one does not constrain the other.

## Alternatives

- **No CLI; use `nixos-rebuild` directly.** Rejected — loses the single memorable
  front door and the real glue (`switch` staging both repos, host auto-detect),
  and the captain values the CLI experience.
- **Write it in a real language (Go, etc.).** Rejected for now — bash fits
  "commands that wrap other commands," and `writeShellApplication` removes bash's
  usual fragility. Revisit only if `account` / `doctor` logic genuinely outgrows
  bash; that logic would move to a tested pure helper, the command surface staying
  bash.
