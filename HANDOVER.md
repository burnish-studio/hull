# Handover — for an agent picking this up cold

Accurate as of **2026-07-24**, end of the Phase 1 session.

## One-line state

Phase 1 is **complete**. NixOS-WSL installs, boots and rebuilds from the hull
flake with **zero errors and exit 0**, verified 2026-07-27 with the other WSL
distro terminated. The user-session failure was traced to an upstream WSL bug
triggered by a second distro running — not hull's config — and is documented
below with an operating rule until Fedora retires in Phase 7.

The immediate next step is Phase 2: the `env` panel and module interfaces.

## Read order

1. **this file** — state + how to work here
2. `README.md` — what hull is, in one screen
3. `docs/adr/0001`–`0005` — the decisions, each a standalone titled ADR
4. `ARCHITECTURE.md` — the target shape
5. `docs/how-it-works.md` — the machinery: flakes vs modules, evaluation vs
   activation, why module order does not matter. Read this before touching
   `flake.nix` or adding a module.
6. `CONTEXT.md` — the glossary / vocabulary
7. `ROADMAP.md` — **the plan ahead** (phases, milestones, open questions)

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

## Current system state (2026-07-27)

- **NixOS-WSL is installed** as a second WSL distro alongside Fedora Remix.
  Launch via Windows Terminal (NixOS tab) or `wsl -d NixOS` in PowerShell.
- **Hull flake is live**: `nixos-rebuild switch --flake github:burnish-studio/hull#wsl`
  drives the system. The repo is public at `github.com/burnish-studio/hull`.
- **`git` and `claude-code` are on the machine** (verified: `git` 2.54.0,
  `claude-code` 2.1.187). **hull is now developed from inside NixOS**, not from
  the Fedora side — see "Working from NixOS" below.
- **Current user**: `nixos` (placeholder — replaced with the real user via the
  registry in Phase 3).
- **`hosts/wsl.nix`** holds the whole host config in five settings —
  `wsl.enable`, `wsl.defaultUser`, flakes, packages, the unfree predicate,
  `stateVersion`. No workarounds.
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

## Working from NixOS (as of 2026-07-27)

hull is developed **on the machine it configures**. Both repos are cloned on the
NixOS side over HTTPS (no SSH identity exists there until Phase 3):

```bash
git clone https://github.com/burnish-studio/hull ~/hull
git clone https://github.com/burnish-studio/hull-fedora ~/hull-fedora   # read-only quarry
sudo nixos-rebuild switch --flake ~/hull#wsl                            # local path, not GitHub
```

**Division of labour:** the agent edits, and runs `nix flake check`,
`nix build --dry-run` and `nixos-rebuild build` freely — all non-destructive. The
captain runs `nixos-rebuild switch` and makes the experiential calls.

**Gate before handing over a change:** `nix build --dry-run
.#nixosConfigurations.wsl.config.system.build.toplevel`. `nix flake check` is
*not* sufficient — it proves the config is well-formed but does not force package
derivations, so it misses unfree-licence and missing-package errors. This was
learned the hard way: `claude-code` was pushed in a state that failed to build
because only `flake check` had been run.

**Gotcha: flakes only see git-tracked files.** A new module is invisible until
`git add`ed. Committing is not required; staging is. The error reads "file does
not exist", which is misleading.

**Expect the `user@1000` exit 4 on every rebuild while Fedora runs.** It is the
documented upstream bug, not a regression. The fix is to stop starting Fedora.

## Disk and generations (policy decided 2026-07-27)

**Keep 3 system generations. Now automatic** — `hosts/wsl.nix` caps them in
`system.activationScripts`, so every `nixos-rebuild switch` enforces the ceiling
however it was invoked. `auto-optimise-store` dedupes continuously. See ADR 0006
for the full reasoning; do not replace either with a timer.

Reclaim (the slow part) is still manual until `hull switch` owns it in Phase 4:

```bash
sudo nix-collect-garbage
```

**Why capping and not periodic cleanup:** WSL keeps the filesystem in a virtual
disk that grows but never shrinks. Space freed inside NixOS is *not* returned to
Windows, so the peak store size is what permanently costs disk. Capping prevents
the peak; cleaning up afterwards does not undo it. A scheduled timer was rejected
for the same reason — it bounds the average, not the peak.

Generations are cheap: the store is content-addressed, so generations sharing the
same nixpkgs revision differ only by what changed. Note the store also holds every
nixpkgs revision ever fetched (~468 MB each), which only `nix-collect-garbage`
clears — so "3 generations" is not the whole footprint.

**Measured 2026-07-27 — keep this in proportion.** NixOS: 8.0 GB used, 7.8 GB of
that the store, virtual disk 9.04 GB (≈1 GB overhead, so nothing meaningful is
trapped and **compaction is not currently needed**). Fedora's virtual disk:
**78.47 GB** — 8.7× the entire NixOS system.

So the generation cap is correct design but a **minor** disk lever today; it earns
its keep once Phase 2 adds neovim, node and the rest. **The real disk win is
retiring Fedora (~78 GB), which also permanently silences the `user@1000`
failure.** Do not spend effort on store micro-management while that 78 GB is
outstanding.

Measure with `df -h /` and `du -sh /nix/store` on NixOS; list generations with
`ls -l /nix/var/nix/profiles/` (`nix-env -p` needs root even to read). Virtual disk
sizes are visible from Windows by walking
`HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss` for each distro's
`BasePath\ext4.vhdx` — unverified beyond the one run above.

**Losing old generations costs time, not recoverability** — hull is in git, so any
past system can be rebuilt from any commit. Generations only buy *instant*
rollback. Hence 3 rather than 10.

**If reclaim is ever needed** (not now — see the measurements above): a WSL virtual
disk grows but never shrinks, so freeing space inside NixOS does not return it to
Windows. The sequence is cap, garbage-collect, then compact from Windows
(`wsl --manage <distro> --set-sparse true` on recent WSL, otherwise
`diskpart`/`Optimize-VHD`). Per hull's boundaries that compaction stays on the
manual Windows checklist alongside WezTerm and fonts — hull never touches Windows.

## What is decided (see the ADRs for the reasoning)

- **0001** — target **NixOS exclusively**; two host types: `wsl` (NixOS-WSL) and
  `native` (NixOS on bare metal). WSL first, native once proven.
- **0002** — **segmentation**: identity-agnostic, host-type-aware; zero identity
  in the tool; multi-account baseline; opinions vs identity are separate axes.
- **0003** — **seam, not repo**: sealed modules ("panels"); split only on a real
  second consumer; registry is the data-exception.
- **0004** — **CLI**: thin wrappers + imperative substance; `writeShellApplication`.
- **0005** — clean-start rewrite; v1 frozen as `hull-fedora`.
- **0006** — **disk hygiene is event-driven on WSL**: the guest sees a fake ~1 TB
  of free space so pressure-driven GC never fires, and the virtual disk never
  shrinks. Cap generations at activation, dedupe continuously, reclaim in the CLI.
  Not inherited by `native`.

## Known issue: `user@1000.service` fails — one root cause, three symptoms

Accurate as of **2026-07-27**. This section supersedes the 2026-07-24 diagnosis,
which was wrong about the mechanism (see "Ruled out" below).

**The three symptoms are all one bug:**
1. On WSL boot: `wsl: Failed to start the systemd user session for 'nixos'`.
2. On `nixos-rebuild switch`: `Failed to open dbus connection` → `Unable to
   autolaunch a dbus-daemon without a $DISPLAY for X11` → `warning: user
   activation for nixos failed`, exit code 4.
3. `systemctl --failed` lists `user@1000.service`.

**The actual root cause**, from the journal (`systemd[1]`, not WSL):
```
systemd[1]: user@1000.service: Failed to spawn executor: Device or resource busy
systemd[1]: user@1000.service: Failed to spawn 'start' task: Device or resource busy
systemd[1]: user@1000.service: Failed with result 'resources'.
```
The chain: systemd cannot spawn the user manager's executor (cgroup-level EBUSY)
→ no user D-Bus socket at `/run/user/1000/bus` → `nixos-rebuild`'s "reloading
user units" step cannot connect → exit 4. WSL's banner is a *downstream report*:
it runs `systemctl is-active user@1000.service`, sees `failed`, and prints.

**Impact is cosmetic.** Despite the `failed` state the manager is actually
running — `systemctl status` shows ~19 tasks in a populated cgroup, and
`loginctl list-sessions` shows an active session. Nothing has malfunctioned.

**Ruled out (do not re-investigate these):**
- **cgroup delegation.** A `systemd.packages` drop-in setting `Delegate=no` /
  `DelegateSubgroup=` was added 2026-07-24 and **removed 2026-07-27**. The
  failure persists on a cold NixOS restart with stock delegation restored
  (`Delegate=pids memory cpu`, `DelegateSubgroup=init.scope`). Do not re-add it.
- **The SIGCHLD / shell-wrapper theory** (the 2026-07-24 claim). The journal
  timeline refutes it: `systemd[1]` fails at `:02`; the WSL interop error and
  `shell-wrapper: SIGCHLD is ignored` both appear at `:03`, *after*. SIGCHLD is a
  separate cosmetic message about environment setup, not the cause.

**It is genuinely upstream, and unfixed.** The same message is reported across
Ubuntu 24.04/26.04, Arch, AlmaLinux and NixOS on WSL 2.6.1.0–2.7.3.0. Microsoft
closed WSL #40590 (2.7.3.0, Ubuntu 26.04) as **"not planned"**. Note our journal
evidence is *more specific* than any upstream report — none of them diagnose the
cgroup layer. Two independent sources correlate it with **another WSL distro
already running**: NixOS-WSL #888 (labelled `upstream-bug`) and WSL #40590, where
it fails "when launching multiple instances sequentially" (`vm_4` fails, `vm_3`
succeeds, identical configs). Intermittency is characteristic — repeat any test
at least twice before believing the result.

**Relevant issues:**
- https://github.com/nix-community/NixOS-WSL/issues/888
- https://github.com/microsoft/WSL/issues/40590 (closed, not planned)
- https://github.com/microsoft/WSL/issues/13564
- https://github.com/microsoft/WSL/issues/13826#issuecomment-3996921259

**CONFIRMED 2026-07-27.** With **both distros terminated** and NixOS opened alone,
twice: no banner, `systemctl --failed` → `0 loaded units listed`, and
`nixos-rebuild switch` completes with `Done.` — no warning, exit 0. The rebuild's
user-unit step now works (`restarting the following user units:
nixos-activation.service`), which is the direct proof of the causal chain: kill
the trigger and all three symptoms clear together.

**So: hull's config is clean. The trigger is a second WSL distro running.**

**Operating rule until Phase 7:** terminate the other distro before opening NixOS.
```powershell
wsl --terminate fedoraremix
wsl --terminate NixOS     # so NixOS cold-boots with Fedora already gone
```
Terminating NixOS too matters — resuming a NixOS session that *started* while
Fedora was up keeps the failed unit. If you see the banner, this is why; it is not
a regression in hull. The problem disappears permanently when Fedora retires.

**Constraint this places on Phase 2:** `systemd.user` services work on a clean
start, but will fail on any boot where Fedora was running. Until Phase 7, do not
make the `env` panel *depend* on Home Manager user services. File-based config
(zsh, neovim, git, starship) is unaffected either way — prefer it.

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
