# hull

The **hull** — the reproducible environment layer of a larger, ship-themed
system: the structural body you work *inside* (shell, editor, terminal, tools,
agent config). This is the **NixOS-native** hull.

> **Status: building (2026-07-28).** NixOS-WSL boots and rebuilds from this
> flake (Phase 1 ✅), and the environment modules — `shell`, `editor`, `tools` —
> are activated and live on the machine (Phase 2 ✅). `git-identity`, `agents`,
> the `hull` CLI and the `native` host are not written yet. New here? Start with
> [`HANDOVER.md`](HANDOVER.md).

## What it is

A NixOS flake that produces one reproducible developer environment across two
host types:

- **`wsl`** — NixOS-WSL, under Windows 11 (the main driver's terminal side).
- **`native`** — NixOS on bare metal (currently a secondary laptop; could be any hardware).

hull holds **no personal identity** — your name, GitHub accounts and keys live in
a separate private **registry** repo, wired in as a flake input. hull is
identity-agnostic and host-type-aware (see [ADR 0002](docs/adr/0002-segmentation.md)).

## Map

| File | What |
| --- | --- |
| [`HANDOVER.md`](HANDOVER.md) | current state + how to work here — **read first** |
| [`ROADMAP.md`](ROADMAP.md) | the plan ahead: phases, milestones, open questions |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | the target shape (flake, hosts, modules, CLI) |
| [`CONTEXT.md`](CONTEXT.md) | glossary / vocabulary |
| [`docs/adr/`](docs/adr/) | the decisions, one titled record each |

## Lineage

Rewritten greenfield from a v1 that ran on Fedora + Home Manager (imperative
bash), now frozen for reference at `~/hull-fedora` on NixOS
(`~/burnish-studio/hull-fedora` on the legacy Fedora distro). The overall
structure is adapted from Kun Chen's macOS/nix-darwin dotfiles
([github.com/kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles)).
