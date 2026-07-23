# Handover — for an agent picking this up cold

Accurate as of **2026-07-23**, end of the greenfield planning session.

## One-line state

hull has just been **restarted greenfield** as a **NixOS-native** environment.
This is the **design phase**: the shape, the decisions and the roadmap are
written, but **nothing has been built or run on NixOS yet.** The previous
implementation (v1) is frozen at `~/burnish-studio/hull-fedora` — reference only,
never edit it.

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

## What is decided (see the ADRs for the reasoning)

- **0001** — target **NixOS exclusively**; two host types, both real test cases:
  `wsl` (NixOS-WSL) and `laptop` (native NixOS). WSL first, laptop once proven.
- **0002** — **segmentation**: identity-agnostic, host-type-aware; zero identity
  in the tool (all in the registry); multi-account is baseline; opinions vs
  identity are separate axes; hull never touches Windows.
- **0003** — **seam, not repo**: isolate concerns as sealed modules ("panels");
  split to a separate repo only on a real second consumer; registry is the
  data-exception.
- **0004** — **CLI**: keep a small CLI that *wraps* native Nix, never
  re-implements it; built as a `writeShellApplication` (bash, shellcheck at build,
  pinned deps). Thin wrappers + the imperative substance (`account`, `doctor`).
- **0005** — **clean-start** rewrite in a fresh repo; v1 frozen as `hull-fedora`.

## What is NOT done (be honest about this)

- **Nothing is built on NixOS.** The flake, the modules, the CLI — all on paper.
  The proof is a first `nixos-rebuild` on WSL (Roadmap Phase 1). Do not report the
  design as working until it runs.
- **Module interfaces are undesigned** — the deep-module work is ahead.
- **Registry ↔ flake wiring** is unsolved (must avoid v1's hardcoded-path "Gap C";
  the registry also has no remote yet).
- **Sharing a `lib/` pure function** between a module and the CLI is unverified.
- **No content has been ported** from `hull-fedora` yet.

## Immediate next step

**Roadmap Phase 1 — prove the substrate.** Disk-clean the Windows host, install
NixOS-WSL beside Fedora Remix, and get a minimal flake to `nixos-rebuild switch`.
Everything else builds on that loop existing. Design work for Phase 2/3 (module
interfaces, the Generator) can be drafted on paper in parallel.

## Working with the captain (alex)

- **He drives the terminal himself** via `! <cmd>` for experiential / destructive
  steps (installs, rebuilds, `chsh`). You design and fix; he runs. Don't run the
  big irreversible steps for him unless asked.
- **He wants to understand before approving.** Explain what/where/why; **verify
  claims, don't assert** — v1 taught that "green" is not "working."
- **Kun Chen's dotfiles are the reference** (github.com/kunchenguid/dotfiles).
  When you diverge from Kun, say so and justify it.
- **Surface problems proactively**; be honest about tested vs not.
- Don't over-expand scope in one go — get one thing working, then improve.
  Let components appear when genuinely needed (pulled, not pushed).

## Hard boundaries (do not cross)

- **hull never touches Windows.** No `/mnt` reads/writes, no `cmd.exe` /
  `powershell.exe`. Security boundary. The Windows-side setup (WezTerm, fonts) is
  a manual checklist. (The neovim `clip.exe` clipboard bridge is the one agreed
  exception, and lives in ported content.)
- **Company network drives** (`/mnt/d`, `/mnt/e`) must never be touched.

## Tooling note

The `/grill-with-docs` and other project skills currently live in
`hull-fedora/.claude/skills`, not here. Copy any you want into this repo's
`.claude/skills/` when needed. This repo has no remote yet (local `main` only).
