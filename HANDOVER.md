# Handover — for an agent picking this up cold

Accurate as of **2026-07-24**, end of the Phase 1 session.

## One-line state

Phase 1 is **substantially complete**: NixOS-WSL is installed, boots, and rebuilds
from the hull flake on GitHub. One known issue remains (user session — see below).
The immediate next step is Phase 2: the `env` panel and module interfaces.

## Read order

1. **this file** — state + how to work here
2. `README.md` — what hull is, in one screen
3. `docs/adr/0001`–`0005` — the decisions, each a standalone titled ADR
4. `ARCHITECTURE.md` — the target shape
5. `CONTEXT.md` — the glossary / vocabulary
6. `ROADMAP.md` — **the plan ahead** (phases, milestones, open questions)

Project memories auto-load at session start — read `hull-greenfield-rewrite`
first; it explains the two-repo split and flags which v1-era memories are
reframed (not gospel).

## The two repos (do not confuse them)

| path | what | edit? |
| --- | --- | --- |
| `~/burnish-studio/hull` | **greenfield**, NixOS-native — this repo, the main hull going forward | yes |
| `~/burnish-studio/hull-fedora` | **frozen v1** (Fedora + Home Manager, imperative bash) | **no — reference only** |

`hull-fedora` is where you *mine* working content (neovim, wezterm, herdr,
starship, the git-identity logic, agent settings) and read the fuller metaphor
(`ARCHITECTURE.md` §1–7) and v1's decisions (`.plan/DECISIONS.md`, the `D1..`
log). Treat it as a quarry and a record — not as gospel; v1 had real bugs.

## Current system state (2026-07-24)

- **NixOS-WSL is installed** as a second WSL distro alongside Fedora Remix.
  Launch via Windows Terminal (NixOS tab) or `wsl -d NixOS` in PowerShell.
- **Hull flake is live**: `nixos-rebuild switch --flake github:burnish-studio/hull#wsl`
  drives the system. The repo is public at `github.com/burnish-studio/hull`.
- **Current user**: `nixos` (placeholder — replaced with the real user via the
  registry in Phase 3).
- **`hosts/wsl.nix` exists** and holds the host-type config (`wsl.enable`,
  `wsl.defaultUser`, `stateVersion`, flakes, `git`) — no workarounds.
- **`flake.lock` is committed.** Both inputs track the **26.05 release line**:
  nixpkgs on `nixos-26.05` (the Hydra-tested channel branch — binaries are in the
  cache; `release-26.05` is the raw one and would mean source builds) and
  nixos-wsl on `release-26.05`. The ref is the *update policy*; the lock supplies
  reproducibility. Do not point either at `main`/unstable without a reason — that
  is how a routine `nix flake update` pulls next-release code onto a 26.05 base.
- **Flakes are declared** in `hosts/wsl.nix`. `nixos-rebuild --flake` passes
  `--extra-experimental-features` itself (nixpkgs
  `pkgs/by-name/ni/nixos-rebuild-ng/src/nixos_rebuild/nix.py`), so rebuilds worked
  without this — but bare `nix` and the Phase 4 CLI need it declared.

## The rebuild workflow (important — read this)

**Ordering matters once.** `git` is now in `hosts/wsl.nix`, but it is not on the
machine until a rebuild installs it. So the *next* rebuild must still come from
GitHub; after that, switch to a local clone permanently.

**Step 1 — bootstrap from GitHub (once):**
```bash
sudo nixos-rebuild switch --flake github:burnish-studio/hull#wsl
```
If it reports "path does not exist" or behaves as if recent changes are missing,
Nix's GitHub fetcher has served a cached commit — pass the hash explicitly:
```bash
sudo nixos-rebuild switch --flake github:burnish-studio/hull/<hash>#wsl
```

**Step 2 — clone locally and never do the above again:**
```bash
git clone https://github.com/burnish-studio/hull ~/hull
sudo nixos-rebuild switch --flake ~/hull#wsl
```
Rebuilding from a local path removes the stale-commit class of failure entirely,
and lets you test uncommitted changes.

## What is decided (see the ADRs for the reasoning)

- **0001** — target **NixOS exclusively**; two host types: `wsl` (NixOS-WSL) and
  `native` (NixOS on bare metal). WSL first, native once proven.
- **0002** — **segmentation**: identity-agnostic, host-type-aware; zero identity
  in the tool; multi-account baseline; opinions vs identity are separate axes.
- **0003** — **seam, not repo**: sealed modules ("panels"); split only on a real
  second consumer; registry is the data-exception.
- **0004** — **CLI**: thin wrappers + imperative substance; `writeShellApplication`.
- **0005** — clean-start rewrite; v1 frozen as `hull-fedora`.

## Known issue: user session fails at boot and during rebuild

**Symptom:** On WSL boot: `wsl: Failed to start the systemd user session for
'nixos'`. On `nixos-rebuild switch`: `warning: user activation for nixos failed`
(exit code 4).

**Cause (researched 2026-07-24):** an upstream **WSL2 interop bug**, labelled as
such by the NixOS-WSL maintainers. It fires only when another WSL distro (Fedora
Remix) is already running when NixOS is opened: WSL's shell wrapper sees that
`SIGCHLD` is being ignored — inherited from the running distro's context — and
skips user session setup. Our own logs showed it directly: `shell-wrapper:
SIGCHLD is ignored, skipping setting environment`. Downstream of that,
`user@1000.service` fails with `Result: resources` / `Failed to spawn executor:
Device or resource busy`. **There is no NixOS-level fix** — the defect is in the
WSL interop layer, above anything hull controls.

**Workaround:** terminate Fedora before opening NixOS:
```powershell
wsl --terminate fedoraremix
```
The problem disappears entirely once Fedora is retired in Phase 7.

**What we tried and removed (2026-07-27):** a `systemd.packages` drop-in on
`user@.service` setting `Delegate=no` / `DelegateSubgroup=`, on the theory that
cgroup delegation was the cause. The drop-in loaded correctly (confirmed via
`systemctl cat`) but the failure persisted — cgroup delegation was *not* the
cause. **The drop-in has been deleted** rather than left in place: a fix that
provably does not fix anything is cruft, and it misattributes an upstream bug to
our config. `hosts/wsl.nix` is now stock host configuration only. Do not
reintroduce a systemd workaround for this symptom without first reproducing it
on a clean start (Fedora terminated).

**Relevant issues:**
- https://github.com/nix-community/NixOS-WSL/issues/888
- https://github.com/microsoft/WSL/issues/13826#issuecomment-3996921259

**Open verification (next session, captain-driven):** confirm that with Fedora
terminated the boot and `nixos-rebuild switch` are both **completely clean** — no
warnings, exit 0. That is the "brand-new NixOS-WSL has zero errors" baseline we
want before building Phase 2 on top of it. If anything still errors on a clean
start, it is *our* problem and takes priority over Phase 2.

## What is NOT done

- **Module interfaces are undesigned** — the deep-module work is Phase 2.
- **No panels exist yet** — `modules/` directory is empty; all content still in
  `hull-fedora`.
- **Registry ↔ flake wiring** is unsolved (registry has no GitHub remote yet;
  must avoid v1's hardcoded-path "Gap C").
- **The `hull` CLI** does not exist yet (Phase 4).
- **The `alex` user** is not configured — current default user is `nixos`.
  Real user comes from the registry (Phase 3).
- **`hosts/native.nix`** does not exist — Phase 6.
- A NixOS minimal ISO is on a USB stick ready for the laptop (Phase 6 prep).

## Immediate next step — Phase 2

Gated on the clean-start verification above passing:

1. **Design the `env` panel interface** — what options does it expose?
   Start with zsh (shell, plugins, prompt via starship) as the first module.
   Reference `hull-fedora` for working content to port.

2. **Create `modules/env/`** — begin with a minimal zsh module that at least
   sets the default shell, then iterate.

Note on porting: v1's environment content is **not** in tidy portable files.
`hull-fedora/home/` holds only `AGENTS.md`; the substance (git identity,
accounts, URL rewrites) is inline in a single monolithic `home.nix`. Phase 2 is
extraction and re-segmentation, not file copying — budget accordingly.

## Working with the captain (alex)

- **He drives the terminal himself** via `! <cmd>` or his NixOS terminal tab
  for experiential / destructive steps (rebuilds, installs). You design and fix;
  he runs.
- **He wants to understand before approving.** Explain what/where/why; verify
  claims, don't assert.
- **Kun Chen's dotfiles are the reference** (github.com/kunchenguid/dotfiles).
  When you diverge, say so and justify it.
- **Minimalism first.** No bloat, no speculative features. If it's not needed
  yet, don't add it.
- **Don't add co-author lines to git commits** on this repo.

## Hard boundaries (do not cross)

- **hull never touches Windows.** No `/mnt` reads/writes, no `cmd.exe` /
  `powershell.exe`. The Windows-side setup (WezTerm, fonts) is a manual
  checklist. (The neovim `clip.exe` clipboard bridge is the one agreed
  exception, and lives in ported content.)
- **Company network drives** (`/mnt/d`, `/mnt/e`) must never be touched.

## Tooling note

Project skills (`/grill-with-docs` etc.) live in `hull-fedora/.claude/skills/`.
Copy into this repo's `.claude/skills/` when needed. This repo has a GitHub
remote at `github.com/burnish-studio/hull` (public).
