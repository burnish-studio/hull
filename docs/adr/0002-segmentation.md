# 2. Segmentation — identity-agnostic, host-type-aware

- Status: Accepted
- Date: 2026-07-23
- Deciders: alex (captain)

## Context

An early framing asked "is hull a personal tool or a shareable one?" That is a
**false choice**. "Personal" was overloaded — it conflated two things that live
on different axes:

- **Opinions** — inherited, set customisations (the Kun-derived house style).
  Opinionated, fixed, impersonal.
- **Identity** — name, GitHub accounts, SSH keys, per-host login. Actual personal
  data.

And a third thing that is neither: **host type** (which kinds of machine are
serviced). Once separated, "shareable vs personal" dissolves: a tool that never
lets identity leak into it is adoptable *as a side effect* of clean segmentation,
not as a goal paid for.

## Decision

The a priori truths the design holds:

- **A. Zero identity in the tool.** No name / account / key / hostname in hull;
  all injected as data (the registry).
- **B. Multi-account is baseline.** Even "just the captain" is N accounts (2
  today). The account list is arbitrary-length data — never special-cased to 2.
- **C. Identity-agnostic, host-type-aware.** hull does not care *who* you are or
  *how many* accounts; it *does* care *what host type* it runs on (NixOS-desktop
  vs NixOS-under-WSL), because that changes what it can manage (GUI, clipboard,
  the Windows wrapper).
- **D. Target platform is NixOS** (see ADR 0001).
- **E. Opinions inherited & fixed; identity injected & per-person.** Neither
  leaks into the other.
- **F. hull never touches Windows.** No `/mnt` access, no `cmd.exe` — a security
  boundary. The Windows-side setup is a manual checklist.

## Consequences

- All identity lives in the registry (a separate private repo, a flake input),
  and nowhere in hull.
- Adoptability by someone else is a free side effect — not a constraint we spend
  effort protecting.
- Host-type awareness is concentrated at the host layer, not smeared through the
  concern modules (see ARCHITECTURE.md).

## Alternatives

- **Make hull explicitly "personal only."** Rejected — the false choice; it would
  invite identity to leak into the tool.
- **Keep "shareable to colleagues" as a first-class goal.** Rejected — it was
  quietly adding weight (registry indirection framed for strangers, an impersonal
  discipline) for a hypothetical audience. Segmentation gives adoptability anyway.
