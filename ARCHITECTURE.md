# Architecture

hull is a NixOS flake that produces a reproducible developer environment for two
host types. This file is the **shape**; the *why* of each choice is in
`docs/adr/`, and the vocabulary is in `CONTEXT.md`.

> Status: **partly built.** `hosts/wsl.nix` and the `shell` / `editor` / `tools` /
> `agents` modules are real and **activated on the WSL host**; `git-identity`,
> `lib/`, `cli/` and `hosts/native.nix` do not exist yet. `agents` is half built -
> the Claude Code package and status line are live, `AGENTS.md` is not. See
> `ROADMAP.md`.

## Top-level layout (`*` = exists today)

```
flake.nix        * inputs (nixpkgs, nixpkgs-unstable, nixos-wsl, home-manager;
                   registry to come); outputs: nixosConfigurations.{wsl,native},
                   packages.hull
hosts/
  wsl.nix        * host type: NixOS-WSL (no GUI; the Windows wrapper stays
                   manual / out-of-tree - hull never touches Windows)
  native.nix       host type: NixOS on bare metal (Wayland, fonts, GUI, wezterm)
modules/           sealed concerns, each with a small typed interface
  paths.nix      * one shared option: where hull is checked out on this machine.
                   Imported by any module using an out-of-store symlink.
  shell/         * zsh, starship, fzf, aliases
  editor/        * neovim + its lua config (linked live, not via the store)
  tools/         * ripgrep, fd, jq, lazygit, node, herdr + herdr's config
  git-identity/    Generator (accounts → gitconfig/ssh) + its Home Manager adapter;
                   consumes the registry
  agents/        * claude-code + its settings and status line, linked out-of-store.
                   AGENTS.md and the one-source-three-targets links are still owed.
lib/               pure helpers - e.g. the git-identity Generator as a pure function,
                   shared by its module adapter and by the CLI
cli/               the `hull` command, a writeShellApplication (see ADR 0004)
docs/adr/        * decision records
```

The **registry** is a separate private repo (identity data), wired in as a flake
input.

**Why `shell` / `editor` / `tools` and not one `env` module** (decided
2026-07-27): `env` was a grab-bag name - it held shell, editor, multiplexer, CLI
tools and a language runtime, and "environment" is what all of hull produces, so
the name distinguished nothing. It also collided with the system map, where "the
ship's body" is hull itself. Three obvious names beat one vague one, the modules
are small but so is `agents`, and merging later is as cheap as splitting later.

**wezterm is not in a shared module.** It is host-level: on WSL it lives on the
Windows side and Nix does not manage it at all; on `native` it belongs in
`hosts/native.nix`. This is the host-type seam working as intended.

## Load-bearing shape decisions

- **Host-type variation lives at the host layer** (not inside the concern
  modules). Concern modules are host-agnostic and expose options; each host file
  imports the concerns it wants and sets their options (e.g. only `native` pulls
  in the GUI parts). Axiom C (host-type-aware, ADR 0002) is satisfied in exactly
  one place, rather than smeared as `if wsl then …` through every concern.
- **Concerns are sealed modules, not separate repos** (ADR 0003). One flake, one
  lock. Each module = pure Generator + optional lifecycle tool + a thin adapter.
- **Home Manager runs as a NixOS module**, not as a standalone
  `homeManagerConfiguration` as in v1. One `nixos-rebuild switch` activates the
  system and the user environment together, atomically, with one generation
  counter and one rollback. v1 needed the standalone form because its host was
  not NixOS; that reason is gone.
- **Store-managed by default; out-of-store by exception.** Config expressed as
  Nix options (zsh, starship, aliases) is generated into the store and changes on
  rebuild. Config iterated on constantly (nvim's lua, herdr's toml) is linked
  straight to the working tree via `mkOutOfStoreSymlink`, so edits are live. The
  exception costs atomic rollback for those files and requires hull to know its
  own path on disk - hence the single `hull.repoPath` option in `modules/paths.nix`
  rather than v1's hardcoded `~/.dotfiles`.
- **The CLI wraps native Nix; it never re-implements it** (ADR 0004). `switch` /
  `diff` / `rollback` / `status` are thin wrappers; `account` / `doctor` are the
  imperative substance. Built and shellcheck'd by Nix.
- **Pure logic is shared, not duplicated.** A Generator in `lib/` is the same
  function whether a module adapter or a CLI command calls it.
- **Foreign binaries are permitted at the host layer, not designed for.** NixOS
  is not a Filesystem Hierarchy Standard system, so prebuilt generic-linux
  executables cannot run unaided. `programs.nix-ld` in `hosts/wsl.nix` supplies a
  real dynamic loader so injected binaries - today, VS Code's server - work. This
  is an escape hatch with a known cost: whatever runs through it is imperative
  and not reproducible from this repo, exactly like lazy.nvim's plugins. Keep the
  set of such things small and named.

## What NixOS gives us for free (so hull must not re-build it)

Login shell, locale, PATH, packages, services - all declarative. `switch` /
`rollback` / generations / atomic activation - all native. v1's imperative
provisioning existed only because the host was foreign; on NixOS it is deleted,
not ported (ADR 0001).
