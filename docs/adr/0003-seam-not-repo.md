# 3. Seam, not repo

- Status: Accepted
- Date: 2026-07-23
- Deciders: alex (captain)

## Context

The instinct for the rewrite is "isolate each self-contained concern, build it
standalone, hook the pieces together with minimal glue" — to be less brittle.
That instinct is right. But it invites a leap: *self-contained ⟹ its own repo,
pulled in as a dependency* ("the hull made of panels from other repos"). That
leap is where v1's worst bugs came from — cross-repo flake-input / lock-file
coordination (the `path:` override / NAR-hash / lock-churn saga).

## Decision

Separate two decisions that the leap conflates:

1. **Isolation** — a sealed interface, no leakage, testable alone. Achieved by
   **module / library discipline**, *not* by a repo boundary. A well-sealed
   module in one repo is already a "panel."
2. **Distribution** — does the sealed unit live in its own *repo*, as a flake
   input? This buys independent reuse / release, and *costs* cross-repo lock
   coordination. **Defer it until a real second consumer exists.**

Standing exception: the **registry** is its own repo, because it is identity
*data* (ADR 0002 axiom A), not because it is a concern.

Worked example — the git-identity concern is Nix-independent at its core and
decomposes into three parts, none needing its own repo yet:

| part | what | Nix? |
| --- | --- | --- |
| **Generator** | pure function: `accounts → config file contents` (gitconfig `includeIf`, ssh config, repo helpers). No side effects. | independent |
| **Lifecycle tool** | imperative CLI: keygen + `gh` upload + registry edit. Nix must never mint secrets at eval time. | independent |
| **Adapter** | thin, per-platform: a Home Manager module wiring the Generator's output into `programs.git` / `programs.ssh`. | hull-specific |

## Consequences

- One flake, one lock file. Modules are independently evaluable and testable.
- Extraction to its own repo later is cheap *because* the seam is already clean —
  do it the day a non-hull consumer (bare Fedora, a colleague) stops being
  hypothetical.
- Deep modules govern: each panel exposes a small typed interface and hides its
  internals.

## Alternatives

- **A separate repo per concern, composed by a top flake.** Rejected now —
  reintroduces exactly the cross-repo lock-coordination bug class, to buy option
  value (independent reuse) that is not being cashed today.
