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
- **`hosts/wsl.nix` exists** with a WSL2 cgroup fix (see Known Issue below).
- **`flake.lock` is committed** — inputs are pinned to nixos-26.05.

## The rebuild workflow (important — read this)

When rebuilding from GitHub, Nix sometimes fetches a cached old commit rather
than HEAD. If the rebuild says "path does not exist" or behaves as if recent
changes are missing, specify the commit hash explicitly:

```bash
sudo nixos-rebuild switch --flake github:burnish-studio/hull/<hash>#wsl
```

Get the latest hash from `git log --oneline -1` on the Fedora side, or from
GitHub. This is a Nix GitHub fetcher cache issue; it goes away once NixOS has
git and can clone the repo locally.

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

**Symptom:** On every WSL boot: `wsl: Failed to start the systemd user session
for 'nixos'`. On every `nixos-rebuild switch`: `warning: user activation for
nixos failed` (exit code 4).

**Root cause:** `user@1000.service` (systemd user session manager) fails with
`Result: resources` / `Failed to spawn executor: Device or resource busy`. This
is a WSL2 cgroup limitation — the user session executor cannot set up the
required cgroup context.

**What we tried:**
- `hosts/wsl.nix` overrides `Delegate=no` and `DelegateSubgroup=` via a
  `systemd.packages` drop-in. The drop-in loads correctly (confirmed via
  `systemctl cat`) but the failure persists — cgroup delegation is not the
  root cause.

**Impact:** None on actual functionality. Shell, sudo, nixos-rebuild, and all
tools work correctly. No user-level systemd services are needed for our WSL
dev environment.

**Root cause (researched 2026-07-24):** This is an upstream WSL2 bug
(labelled as such by NixOS-WSL maintainers). It occurs specifically when
another WSL distro (Fedora Remix) is already running when NixOS is opened.
WSL's shell wrapper detects that `SIGCHLD` is being ignored (inherited from
the already-running distro context) and skips user session setup. We saw this
directly in our logs: `shell-wrapper: SIGCHLD is ignored, skipping setting
environment`. There is no NixOS-level fix — it's in the WSL interop layer.

**Workaround:** terminate Fedora before opening NixOS:
```powershell
wsl --terminate fedoraremix
```
Then open NixOS — the user session starts cleanly. The problem disappears
entirely once Fedora is retired in Phase 7.

**The `hosts/wsl.nix` drop-in** (`Delegate=no`, `DelegateSubgroup=`) can be
removed if it proves unnecessary once the SIGCHLD issue is understood. It does
no harm but may not be the right fix.

**Relevant issues:**
- https://github.com/nix-community/NixOS-WSL/issues/888
- https://github.com/microsoft/WSL/issues/13826#issuecomment-3996921259

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

Assuming the user session issue is either resolved or accepted:

1. **Investigate the NixOS-WSL issue tracker** for the `user@.service` EBUSY
   error — 15 minutes max. If there's a clean fix, apply it. If not, add a
   comment to `hosts/wsl.nix` and move on.

2. **Design the `env` panel interface** — what options does it expose?
   Start with zsh (shell, plugins, prompt via starship) as the first module.
   Reference `hull-fedora` for working content to port.

3. **Create `modules/env/`** — begin with a minimal zsh module that at least
   sets the default shell, then iterate.

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
