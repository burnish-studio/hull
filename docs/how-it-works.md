# How a rebuild actually works

The mechanics of this repo: what each file is, how the pieces combine, and what
`nixos-rebuild` does with them. `ARCHITECTURE.md` describes the *shape* we are
building toward; this describes the *machinery* it runs on.

## Two layers that are easy to confuse

Nix has two independent systems at play here. Almost every point of confusion
comes from blurring them.

| | Flakes | The NixOS module system |
| --- | --- | --- |
| Job | where code comes from, what this repo produces | what the machine should be |
| Unit | a flake (a dir with `flake.nix`) | a module (a `.nix` file) |
| Analogy | `package.json` + `package-lock.json` | the config itself |

They are orthogonal. You can run NixOS without flakes (channels plus
`/etc/nixos/configuration.nix`), and you can use flakes without NixOS (just a dev
shell). We use both, for different reasons.

## What a flake is

A flake is **not** a system definition. It is a directory containing a
`flake.nix` that declares two things:

- **`inputs`** — other flakes this one depends on, pinned in `flake.lock`.
- **`outputs`** — named values this flake produces.

That is all. A flake is a dependency manifest plus an export list, with a
standard interface so other flakes can consume it.

A flake can output anything: packages, dev shells, library functions, overlays,
NixOS modules, NixOS configurations. Ours currently outputs exactly one thing —
`nixosConfigurations.wsl`. It will later also output `packages.hull` (the CLI)
and `nixosConfigurations.native`. Output *names* are conventional, not magic:
tools look for `nixosConfigurations.<host>`, `packages.<system>.<name>`,
`nixosModules.<name>`, and `default` means "the main one".

Flakes are still a Nix experimental feature; `hosts/wsl.nix` enables them
explicitly so bare `nix` commands work (see that file's comment).

## What a module is

A NixOS module is a `.nix` file that does either or both of:

- **declares options** — creates a setting, with a type and a default.
- **sets values** — fills in settings that some module declared.

`hosts/wsl.nix` only sets values. `nixos-wsl`'s `wsl-distro.nix` declares
`options.wsl.enable`, `options.wsl.defaultUser` and friends — which is the only
reason we can write `wsl.enable = true` at all. That option does not exist in
stock NixOS.

**`hosts/wsl.nix` is our `configuration.nix`.** On a traditional NixOS install,
`/etc/nixos/configuration.nix` is just a module that `nixos-rebuild` finds by
convention. Ours is the same kind of file; the only difference is that we name it
explicitly in `flake.nix` instead of relying on a fixed path. Putting it in the
repo is what lets one repo hold several machines — `hosts/wsl.nix` and later
`hosts/native.nix` are two `configuration.nix`-equivalents side by side.

## What `nixos-wsl.nixosModules.default` is

Read it as three parts:

- `nixos-wsl` — our flake **input**, bound by name in `outputs = { ... }`.
- `.nixosModules` — the conventional output attribute for "NixOS modules I
  provide".
- `.default` — the conventional name for the main one.

In NixOS-WSL's own `flake.nix` it resolves to:

```nix
nixosModules.wsl = { imports = [ ./modules ... ]; };
nixosModules.default = self.nixosModules.wsl;
```

So it is **a NixOS module — the same kind of object as `hosts/wsl.nix`** — that
does nothing but import eleven others: `wsl-distro.nix`, `interop.nix`,
`wsl-conf.nix`, `ssh-agent.nix`, `welcome.nix`, `recovery.nix` and so on, one per
concern. (Worth noting: upstream already uses the sealed-module pattern ADR 0003
argues for.)

The key unlock: **everything in the `modules = [ ... ]` list is the same kind of
thing.** One is ours and local, one is theirs and fetched. The module system does
not distinguish.

## Modules merge; they do not run in order

Reordering the `modules = [ ... ]` list changes nothing. Every module contributes
to one shared attribute set, and the module system merges all contributions
before anything is built.

Conflicts resolve by **priority, not position**:

- `mkDefault` — weak, easily overridden
- a plain value — normal
- `mkForce` — wins (NixOS-WSL uses this: `nixpkgs.flake.source = lib.mkForce null`)

Two modules setting the same option at the same priority is an **error**, not a
silent last-wins. That property is what makes this safe at scale, and it is why
adding `modules/env/` in Phase 2 needs no load-order reasoning.

## Evaluation, then activation

`nixos-rebuild switch` is two phases, and they fail in completely different ways.

**Phase A — evaluation.** Nix reads the `.nix` files and computes one derivation
for the whole system. Pure; nothing touches the machine. `nix flake check` and
`nixos-rebuild build` stop here — which is why they are safe to run freely.

**Phase B — activation.** A script makes the running machine match that
derivation. Imperative and side-effecting; this is where runtime failures live.

Annotated from a real run:

```
building the system configuration...        ← Phase A ends
Checking switch inhibitors... done
activating the configuration...             ← Phase B begins
setting up /run/booted-system...
setting up /bin...                          ← wsl-distro.nix's populateBin
setting up /etc...                          ← every environment.etc entry
setting up /sbin/init shim...
reloading user units for nixos...           ← needs the user D-Bus socket
restarting sysinit-reactivation.target
Done. The new configuration is /nix/store/…-nixos-system-nixos-26.05
```

The distinction is not academic. The `user@1000.service` bug (see HANDOVER) failed
only at `reloading user units` — Phase A had succeeded perfectly. That is how we
knew the config was never at fault.

The final store path **is** the system. `switch` points `/run/current-system` at
it and registers a generation, which is why `nixos-rebuild switch --rollback` is
instant and safe.

## Where the rest of hull will slot in

- `modules/env/`, `modules/git-identity/`, `modules/agents/` — more modules in the
  same merge, imported by `hosts/*.nix`.
- `lib/` — plain functions called during Phase A; no module system involvement.
- `cli/` — a **package**, not a module. `hull switch` shells out to
  `nixos-rebuild` (ADR 0004).
- the registry — another flake input, so identity data enters at Phase A and is
  baked into the derivation.

## Gotcha: flakes only see git-tracked files

A new file is invisible to the flake until it is `git add`ed. Committing is not
required, but staging is. The error looks like "file does not exist", which is
misleading. This bites constantly when adding modules.
