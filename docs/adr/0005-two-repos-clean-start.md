# 5. Two repos — a clean-start rewrite

- Status: Accepted
- Date: 2026-07-23
- Deciders: alex (captain)

## Context

v1 (Fedora + Home Manager standalone, an imperative bash `hull`) worked and was
applied green on WSL, but its bugs were concentrated in the imperative
provisioning layer, and its planning had accreted as a running `D1..` decision
log. Committing to NixOS (ADR 0001) makes most of that layer vanish. The captain
wanted a **genuine clean slate** — greenfield planning, not a continuation of
v1's docs and numbering.

## Decision

Rewrite greenfield in a **fresh repo** at `~/burnish-studio/hull`. Freeze v1 at
`~/burnish-studio/hull-fedora` — **reference-only, never edited**. Named by
substrate (`-fedora`), not ordinal (`-mark1`): the true distinguisher is the
target platform.

What moves where:

| layer | disposition |
| --- | --- |
| provisioning / structure (bash `hull`, `chsh` / locale / PATH hacks, bootstrap) | **left behind** — the buggy layer, born of the foreign host; NixOS-native replacement written fresh |
| content (neovim, wezterm, herdr, starship, tool list, git-identity Generator logic, agent settings / `AGENTS.md`) | **carried forward + quality-checked** — substrate-independent and working; not rewritten for its own sake |
| understanding (the metaphor, the project memories) | **carried forward** — not Fedora-specific |

"Don't blindly yield to prior work" applies to *unverified* code (the bash), not
to *demonstrably working* config. Quality-check ≠ rewrite.

## Consequences

- Clean git history and clean planning from commit 1; v1 fully preserved for
  reference and possible future revival.
- The content port from `hull-fedora` is a deliberate, still-pending task (see
  ROADMAP.md) — not an automatic copy.
- A fresh agent must know both repos exist and which is which (recorded in the
  `hull-greenfield-rewrite` project memory).

## Alternatives

- **Same repo, fresh `main` branch** (tag v1 as `v1-fedora`). Rejected — the old
  docs still linger in history / on the branch; less clean than the captain asked
  for.
- **Evolve v1 in place.** Rejected — carries the imperative layer and the accreted
  `D1..` baggage the clean start exists to escape.
