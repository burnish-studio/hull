# Roadmap

Where hull is going. Phases are ordered by dependency; Phase 1 (a real build on
NixOS) unblocks everything, but the design work in later phases can be drafted on
paper in parallel. State and read-order live in `HANDOVER.md`; the *why* behind
each decision is in `docs/adr/`.

**Definition of done (greenfield v1):** both host types green, both GitHub
accounts routing correctly and verified live, the `hull` CLI building with
shellcheck + tests passing, and Fedora retired.

## Phase 0 — Planning slate ✅ (done 2026-07-23)

Fresh repo stood up; v1 frozen at `hull-fedora`; decisions captured as ADRs
0001–0005; architecture shape, glossary and this roadmap written.

## Phase 1 — Prove the substrate on WSL ✅ (substantially done 2026-07-24)

- [x] Disk cleanup on the Windows host — 67.5 GB free (2026-07-24).
- [x] NixOS-WSL installed as a second distro beside Fedora Remix.
- [x] Minimal `flake.nix` producing `nixosConfigurations.wsl`.
- [x] `hosts/wsl.nix` created — the host-type config, stock settings only.
- [x] `flake.lock` committed — both inputs on the 26.05 release line (nixpkgs
      `nixos-26.05`, nixos-wsl `release-26.05`); no unstable/`main` refs.
- [x] Flakes declared in-config; `git` added so hull can be cloned and rebuilt
      from a local path (kills the stale-GitHub-commit failure mode).
- [x] Repo public at `github.com/burnish-studio/hull`; rebuilds from GitHub.
- [x] User session failure re-diagnosed 2026-07-27: root cause is
      `Failed to spawn executor: Device or resource busy` from `systemd[1]`; the
      WSL banner, the dbus error and exit 4 are all downstream of it. Upstream
      and unfixed (Microsoft closed WSL #40590 as not planned). Cosmetic — the
      manager is in fact running. Cgroup delegation and the SIGCHLD theory are
      both ruled out; the drop-in is removed. See HANDOVER.md.
- [ ] **Final test:** with Fedora terminated, open NixOS twice and check
      `systemctl --failed`. Clean → accept as the multi-distro upstream bug,
      gone when Fedora retires in Phase 7, proceed to Phase 2. Still failing →
      the correlation is wrong for us and it needs a fresh look first.
- **Milestone:** NixOS-WSL boots and rebuilds from the hull flake. ✅

## Phase 2 — Module interfaces + the `env` panel

- [ ] Design each panel's **option interface** (the deep-module work — what each
      module exposes vs hides). This is where quality is won; do it deliberately.
- [ ] Port the environment content from `hull-fedora`, quality-checking each
      piece (zsh, neovim, wezterm, herdr, starship, the CLI tool list, Node).
      Carry working config; do not rewrite for its own sake (ADR 0005).
- **Milestone:** `hull switch` yields the full interactive environment on WSL.

## Phase 3 — The `git-identity` panel

- [ ] The **Generator** as a pure function in `lib/` (accounts → gitconfig +
      ssh config + repo helpers), with unit tests.
- [ ] The Home Manager **adapter** wiring it into `programs.git` / `programs.ssh`.
- [ ] Wire the **registry** in as a flake input *cleanly and portably* — the
      explicit fix for v1's "Gap C" (a hardcoded absolute hull path).
- [ ] The account **lifecycle** (`hull account add/remove/list`) and `hull
      doctor` live verification.
- **Milestone:** both accounts route correctly, proven live by `hull doctor`.

## Phase 4 — The `hull` CLI proper

- [ ] `writeShellApplication` package: the thin wrappers (`switch` / `diff` /
      `rollback` / `update`) + the imperative substance (`account`, `doctor`),
      deps pinned, shellcheck green (ADR 0004).
- [ ] `hull version` — read-only: current revision, nixpkgs lock date + how far
      behind channel tip, active generation and host type.
- [ ] `hull update` — `nix flake update` + `nixos-rebuild switch` in one step;
      `hull update --check` to preview what would change without applying.
- [ ] A **fake-`$HOME` test harness** for `account` / `doctor` from the start —
      the only genuinely risky code left.
- **Milestone:** the `hull` package builds, shellcheck passes, tests pass.

## Phase 5 — The `agents` panel

- [ ] Port claude config, `AGENTS.md`, statusline from `hull-fedora`, quality-checked.

## Phase 6 — The native host (bare metal NixOS)

- [ ] Native NixOS install on the (non-precious) machine; `hosts/native.nix` with
      the GUI layer (Wayland, fonts, wezterm).
- [ ] `hull diff` / `switch` / `doctor` green on the native host.
- **Milestone:** both host types green — the host-type seam (axiom C) is proven.

## Phase 7 — Retire Fedora

- [ ] Once WSL and native are both proven, retire the Fedora Remix WSL distro.
- [ ] The Windows-side manual checklist (WezTerm, Hack Nerd Font, `.wezterm.lua`).

## Open questions to resolve as we go

- **Module interface design** — the exact options each panel exposes. Undesigned.
- **Registry ↔ flake wiring** — `github:<you>/registry` input vs a path override;
  must be portable (no hardcoded machine paths). Prerequisite: push the registry
  to a private remote (it has none yet).
- **Sharing a `lib/` pure function** between a NixOS/HM module and the CLI
  package — sound in principle, mechanism not yet verified.
- **Node / pnpm under NixOS** — pin via nix packages, not nvm/corepack (v1's
  deferred decision). Confirm on first `env` build.
- **Secrets** — SSH keys stay per-machine, generated by the lifecycle tool, never
  in Nix. Confirm no `sops`/`agenix` is needed yet.
- **Content audit** — for each `hull-fedora` config, decide carry-as-is vs
  re-derive. Some (locale/PATH shims) are foreign-host artifacts to drop.
