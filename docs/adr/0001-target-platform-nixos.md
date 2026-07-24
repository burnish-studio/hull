# 1. Target platform is NixOS

- Status: Accepted
- Date: 2026-07-23
- Deciders: alex (captain)

## Context

v1 (frozen at `../../../hull-fedora`) provisioned a *foreign*, non-NixOS host
(Fedora + Home Manager standalone) imperatively: a bash `hull` command did
file-moves, `chsh`, `/etc/shells` registration, a locale override, a PATH fix,
and a Determinate-Nix bootstrap. Nearly every bug in v1 lived in that imperative
layer — bash doing systems work (symlinks, stdin, locks, sockets). Nix already
manages the whole environment; committing fully to NixOS removes the foreign-host
impedance rather than continuing to paper over it.

## Decision

The greenfield hull targets **NixOS exclusively**. Non-NixOS hosts are out of
scope. Two host types are serviced, and both are real test cases:

- **`wsl`** — NixOS-WSL under Windows 11 (the main driver's terminal side). The
  GUI lives on Windows via a manual wrapper; hull never touches Windows.
- **`native`** — NixOS on bare metal (real Wayland / hardware; currently a secondary laptop, but the label is hardware-agnostic).

Target platform is decoupled from migration schedule: stand NixOS-WSL up *beside*
the current Fedora Remix and retire it once proven (WSL first — cheapest to
stand up); migrate the native host once the design is proven there (its state is
non-precious, so the remaining risk is technical, not data-loss).

## Consequences

- The entire imperative provisioning layer from v1 — `chsh`, `/etc/shells`,
  locale override, PATH fix, Determinate bootstrap, file-move/backup machinery —
  **ceases to exist.** NixOS makes login shell, locale, PATH, packages and
  services declarative and atomic, with generations and rollback built in.
- The CLI shrinks to only what is genuinely imperative (e.g. SSH key lifecycle);
  most of v1's `hull` subcommands are subsumed by `nixos-rebuild` and nix itself.
  Exact CLI surface: a later ADR.
- Two WSL distros side-by-side cost disk; a focused cleanup on the Windows host
  is a prerequisite, not an afterthought.
- Adoptability narrows to NixOS users. Accepted — adoptability is a *side effect*
  of clean segmentation, not a goal we pay for (see the segmentation ADR).

## Alternatives

- **Stay on Fedora + Home Manager (v1's approach).** Rejected: keeps the
  foreign-host imperative layer that produced nearly all the bugs, for no benefit
  now that full NixOS is on the table.
- **NixOS on the native host only; keep WSL on Fedora + HM.** Rejected: leaves two
  substrates to maintain and never proves the NixOS-WSL host type — which is the
  main driver.
