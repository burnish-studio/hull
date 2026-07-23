# Architecture

hull is a NixOS flake that produces a reproducible developer environment for two
host types. This file is the **shape**; the *why* of each choice is in
`docs/adr/`, and the vocabulary is in `CONTEXT.md`.

> Status: **design phase.** The shape below is agreed; nothing has been built or
> run on NixOS yet. See `ROADMAP.md`.

## Top-level layout (target)

```
flake.nix          inputs (nixpkgs, home-manager, nixos-wsl, registry);
                   outputs: nixosConfigurations.{wsl,laptop}, packages.hull
hosts/
  wsl.nix          host type: NixOS-WSL (no GUI; the Windows wrapper stays
                   manual / out-of-tree — hull never touches Windows)
  laptop.nix       host type: native desktop (Wayland, fonts, GUI)
modules/           the panels — each a sealed concern with a small typed interface
  env/             the ship's body: zsh, neovim, wezterm, CLI tools, herdr, starship
  git-identity/    Generator (accounts → gitconfig/ssh) + its Home Manager adapter;
                   consumes the registry
  agents/          claude config, AGENTS.md, statusline
lib/               pure helpers — e.g. the git-identity Generator as a pure function,
                   shared by its module adapter and by the CLI
cli/               the `hull` command, a writeShellApplication (see ADR 0004)
docs/adr/          decision records
```

The **registry** is a separate private repo (identity data), wired in as a flake
input.

## Load-bearing shape decisions

- **Host-type variation lives at the host layer** (not inside the concern
  modules). Concern modules are host-agnostic and expose options; each host file
  imports the concerns it wants and sets their options (e.g. only `laptop` pulls
  in the GUI parts). Axiom C (host-type-aware, ADR 0002) is satisfied in exactly
  one place, rather than smeared as `if wsl then …` through every concern.
- **Panels are sealed modules, not separate repos** (ADR 0003). One flake, one
  lock. Each panel = pure Generator + optional lifecycle tool + a thin adapter.
- **The CLI wraps native Nix; it never re-implements it** (ADR 0004). `switch` /
  `diff` / `rollback` / `status` are thin wrappers; `account` / `doctor` are the
  imperative substance. Built and shellcheck'd by Nix.
- **Pure logic is shared, not duplicated.** A Generator in `lib/` is the same
  function whether a module adapter or a CLI command calls it.

## What NixOS gives us for free (so hull must not re-build it)

Login shell, locale, PATH, packages, services — all declarative. `switch` /
`rollback` / generations / atomic activation — all native. v1's imperative
provisioning existed only because the host was foreign; on NixOS it is deleted,
not ported (ADR 0001).
