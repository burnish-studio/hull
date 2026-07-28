# Roadmap

Where hull is going. Phases are ordered by dependency; Phase 1 (a real build on
NixOS) unblocks everything, but the design work in later phases can be drafted on
paper in parallel. State and read-order live in `HANDOVER.md`; the *why* behind
each decision is in `docs/adr/`.

**Definition of done (greenfield v1):** both host types green, both GitHub
accounts routing correctly and verified live, the `hull` CLI building with
shellcheck + tests passing, and Fedora retired.

## Phase 0 - Planning slate ✅ (done 2026-07-23)

Fresh repo stood up; v1 frozen at `hull-fedora`; decisions captured as ADRs
0001–0005; architecture shape, glossary and this roadmap written.

## Phase 1 - Prove the substrate on WSL ✅ (done 2026-07-27)

- [x] Disk cleanup on the Windows host - 67.5 GB free (2026-07-24).
- [x] NixOS-WSL installed as a second distro beside Fedora Remix.
- [x] Minimal `flake.nix` producing `nixosConfigurations.wsl`.
- [x] `hosts/wsl.nix` created - the host-type config, stock settings only.
- [x] `flake.lock` committed - both inputs on the 26.05 release line (nixpkgs
      `nixos-26.05`, nixos-wsl `release-26.05`); no unstable/`main` refs.
- [x] Flakes declared in-config; `git` added so hull can be cloned and rebuilt
      from a local path (kills the stale-GitHub-commit failure mode).
- [x] Repo public at `github.com/burnish-studio/hull`; rebuilds from GitHub.
- [x] User session failure re-diagnosed 2026-07-27: root cause is
      `Failed to spawn executor: Device or resource busy` from `systemd[1]`; the
      WSL banner, the dbus error and exit 4 are all downstream of it. Upstream
      and unfixed (Microsoft closed WSL #40590 as not planned). Cosmetic - the
      manager is in fact running. Cgroup delegation and the SIGCHLD theory are
      both ruled out; the drop-in is removed. See HANDOVER.md.
- [x] **Zero-error baseline confirmed** (2026-07-27): with the other distro
      terminated, NixOS opens twice with no banner, `systemctl --failed` empty,
      and `nixos-rebuild switch` finishes `Done.` at exit 0. Trigger is a second
      WSL distro running; it retires with Fedora in Phase 7.
- **Milestone:** NixOS-WSL boots and rebuilds from the hull flake. ✅

## Phase 2 - The environment modules (`shell`, `editor`, `tools`)

**Scope correction (2026-07-27).** This phase was written as "design each
module's option interface" - deep-module work done deliberately up front. That
was overbuilt. With one host consuming these modules, there is nothing to design:
options exist to let a *second* consumer differ, and the second consumer
(`native`) does not exist yet. Designing its interface now would be guessing.
The content itself is ~60 lines of Home Manager options that port near-verbatim.
So Phase 2 is **porting**, and options get added in Phase 6 when `native` shows
what actually needs to vary. The genuine deep-module work is Phase 3's
`git-identity`, which has real logic and a data dependency.

- [x] home-manager added as a flake input on `release-26.05`, wired as a **NixOS
      module** (not v1's standalone `homeManagerConfiguration`) so one
      `nixos-rebuild switch` activates system and user environment atomically.
- [x] `modules/shell` - zsh + autosuggestion + syntax highlighting, starship,
      fzf, aliases. zsh set as the login shell at the host level.
- [x] `modules/editor` - neovim + the lua config, linked out-of-store.
- [x] `modules/tools` - ripgrep, fd, jq, lazygit, nodejs_22, herdr + its config.
- [x] `modules/paths.nix` - the `hull.repoPath` option; fixes v1's hardcoded
      `~/.dotfiles` (Gap C) for out-of-store links.
- [x] Dropped on port: v1's `glibcLocales` override and `LOCALE_ARCHIVE` /
      `LANG` (NixOS sets these correctly; they were Fedora artifacts), and
      `home.sessionPath = ~/.local/bin` (v1's imperative CLI launcher - Phase 4's
      CLI is a Nix package and needs no such path).
- [x] `nixos-rebuild build` green, out-of-store links verified to resolve into
      the working tree, login shell verified as zsh.
- [x] **`nixos-rebuild switch` run 2026-07-28.** Generation 10; zsh live as the
      login shell; all user packages resolve; both out-of-store links resolve
      into the working tree; the generation cap dropped 7 during the switch.
- [x] `programs.nix-ld.enable` added so VS Code Remote-WSL can run its injected
      generic-linux `node`. Host-layer, not a module - `native` should decide
      deliberately in Phase 6 rather than inherit it. See HANDOVER.
- [x] **Confirmed experientially 2026-07-28.** nvim launched for the first time;
      lazy.nvim bootstrapped and installed all 9 pinned plugins with
      `lazy-lock.json` unchanged afterwards; rose-pine renders correctly in
      truecolor; the prompt, autosuggestions and aliases are live. A `COLORTERM`
      truecolor worry was raised and disproved - neovim queries the terminal
      directly rather than trusting that variable.
- [x] **herdr keybindings reverted to herdr's own defaults** (2026-07-28). Eight
      of the twelve inherited settings merely restated defaults; three were tmux
      overrides carried from Kun, which buy nothing without tmux muscle memory.
      Only `copy_mode` was a real decision. See the module comment and HANDOVER.
- **Milestone:** the full interactive environment on WSL. ✅ *(Activated, and now
  verified by use.)*

## Phase 3 - The `git-identity` module

**Carry-forward constraints from v1 - do not rediscover these** (`hull-fedora/.plan/DECISIONS.md`):

- **D1.3 - SSH must go over `ssh.github.com:443`, unconditionally.** Port 22 is
  firewalled on the captain's work network; a plain `git@github.com:` remote times
  out there. Make 443 universal rather than conditional, so there is no failure
  mode that only appears at the office.
- **D1.5 - canonical org-based naming.** Aliases `github-burnish` /
  `github-flintec`; keys `id_ed25519_burnish` / `id_ed25519_flintec`. Org names
  scale to a third account; "personal/work" does not.
- **hull generates ssh *config*, never key material.** Keypairs are per-machine,
  created by `hull account add`, never in Nix or git.
- **D1.4 - keep `gh auth git-credential`** as the fallback for third-party HTTPS
  repos, but nothing load-bearing should depend on which gh account is active.
- **D3.2 - accounts live in a committed `profile.nix`**, not a gitignored one:
  flakes cannot see untracked files.

**Identity settled 2026-07-28** - the data this module generates from is now
decided, so Phase 3 has no naming questions left. `alx` as git `user.name` on
both accounts; per-account GitHub noreply addresses as `user.email`. Full values
and reasoning in HANDOVER.

**Carried from the v1 registry review (2026-07-28) - three things must not port:**
1. `hull.url = "path:/home/adam/burnish-studio/hull-fedora"` - this *is* "Gap C",
   preserved in the file: an absolute path, the old username, and pointing at the
   frozen v1.
2. **The dependency direction inverts.** v1 had registry depending on hull and
   calling `hull.lib.mkHome`. Here **hull takes registry as an input** and
   registry becomes pure data, because hull produces `nixosConfigurations` and
   owns the hosts. Confirmed by the captain 2026-07-28.
3. `fullName = "alex"` with `hosts.wsl.username = "adam"` - the naming drift
   `alx` exists to end. `hosts.<name>.username` becomes `alx` on both hosts,
   which is also what drives the `nixos` → `alx` account rename.

Worth keeping: the `accounts` structure, the org/alias/key naming (already
matches D1.5), and `default = true` on burnish.

**Interim state (2026-07-27):** NixOS is authenticated as `burnish-studio` via
`gh auth login` over HTTPS. There is deliberately **no SSH key, no
`~/.ssh/config`, and no gitconfig `includeIf`** on that machine, so Phase 3 builds
them from the registry rather than reconciling hand-made versions. The second
account is not configured either - it earns its keep when Phase 3 proves that
routing actually works.

- [ ] The **Generator** as a pure function in `lib/` (accounts → gitconfig +
      ssh config + repo helpers), with unit tests.
- [ ] The Home Manager **adapter** wiring it into `programs.git` / `programs.ssh`.
- [ ] Wire the **registry** in as a flake input *cleanly and portably* - the
      explicit fix for v1's "Gap C" (a hardcoded absolute hull path).
- [ ] The account **lifecycle** (`hull account add/remove/list`) and `hull
      doctor` live verification.
- **Milestone:** both accounts route correctly, proven live by `hull doctor`.

## Phase 4 - The `hull` CLI proper

- [ ] `writeShellApplication` package: the thin wrappers (`switch` / `diff` /
      `rollback` / `update`) + the imperative substance (`account`, `doctor`),
      deps pinned, shellcheck green (ADR 0004).
- [ ] `hull version` - read-only: current revision, nixpkgs lock date + how far
      behind channel tip, active generation and host type.
- [ ] `hull update` - `nix flake update` + `nixos-rebuild switch` in one step;
      `hull update --check` to preview what would change without applying.
- [ ] A **fake-`$HOME` test harness** for `account` / `doctor` from the start -
      the only genuinely risky code left.
- [ ] **Disk hygiene, layer 3 (ADR 0006).** Layers 1–2 are already live in
      `hosts/wsl.nix` (generation cap at activation, `auto-optimise-store`). The
      CLI owns reclaim and visibility:
      - `hull switch` - `nix-collect-garbage` after switching.
      - `hull update` - collect after `nix flake update`; that is the single
        largest growth event (~468 MB per nixpkgs revision, plus everything
        rebuilt against it).
      - `hull doctor` - report store size and generation count, and state plainly
        that the guest's free-space figure is meaningless on WSL. It must
        contradict `df`, not repeat it. The virtual disk size is not readable from
        inside the guest, so point at Windows rather than guess.
      - `hull doctor` - **home-directory audit** (decided 2026-07-28). Hold a
        declared list of expected paths (Home-Manager-managed files, the SSH
        keys, known caches) and report anything in `$HOME` hull does not
        recognise. This is the answer to "the home directory accumulates things
        and I cannot tell what is legitimate" - see "What Nix owns" in HANDOVER
        for why declaring `$HOME` itself is the wrong fix. Must also measure the
        home directory separately from the store: `~/.vscode-server-insiders`
        alone is 675 MB and `du -sh /nix/store` cannot see it.
- **Milestone:** the `hull` package builds, shellcheck passes, tests pass.

## Phase 5 - The `agents` module

**Started early, 2026-07-28**, because the captain wanted his status line and
that is real demand rather than speculative work. The wiring half is done and
live; the content half is not.

- [x] `modules/agents` created; `settings.json` and the status line ported from
      `hull-fedora` and linked out-of-store so they are edited live.
- [x] `claude-code` moved out of `hosts/wsl.nix` into this module, and from a
      **system** package to a **user** package - the root-needs-it reason that
      keeps `git` and `gh` system-wide never applied to it.
- [x] Status line quality-checked rather than copied. Three defects fixed: a
      python3 parse that could not run on NixOS at all, a 1s timeout on a 1.06s
      call that could never succeed, and hardcoded account names that breached
      ADR 0002 in a public repo. Full detail in HANDOVER.
- [x] Client-scoped entries dropped on port - a `WebFetch` domain allowance and
      an enabled plugin. Project-scoped settings belong in that project's own
      `.claude/settings.json`, not in hull, and the domain named a client.
- [ ] Adopt Kun's **one-source-three-targets** pattern (reviewed 2026-07-28): a
      single `AGENTS.md` in the repo, linked out-of-store to `.claude/CLAUDE.md`,
      `.codex/AGENTS.md` and `.config/opencode/AGENTS.md`. One source of truth,
      every agent tool reads it. See `~/dotfiles/home.nix`.
- [ ] Extract the house style (adopted 2026-07-28, currently recorded in
      HANDOVER) into hull's own `AGENTS.md`, and link it to the three agent
      tools. This is a *content* decision - what hull's agent instructions
      actually say - which is why it did not ride along with the wiring.

## Phase 6 - The native host (bare metal NixOS)

- [ ] Native NixOS install on the (non-precious) machine; `hosts/native.nix` with
      the GUI layer (Wayland, fonts, wezterm). Mine `~/dotfiles` for
      `home/.config/wezterm/wezterm.lua` and for font management via
      `fonts.fontconfig.enable` - both are manual Windows-side items on WSL and
      become declarative here.
      **Use `nerd-fonts.jetbrains-mono`, not Kun's `nerd-fonts.hack`** (decided
      2026-07-28). JetBrainsMono Nerd Font is what is installed Windows-side and
      renders the status line's Plane-15 glyphs correctly, verified live. The
      ported `wezterm.lua` still says `Hack Nerd Font`, inherited from Kun and
      describing his Mac; change it with the port so both host types agree.
- [ ] Decide deliberately whether `native` wants `programs.nix-ld`. WSL needs it
      for VS Code's injected server; a native host may not need it at all.
- [ ] **Do not copy the WSL disk-hygiene block** (ADR 0006). On a real disk,
      pressure-driven `nix.settings.min-free` / `max-free` is the correct mechanism
      and the activation-time cap is unnecessary. This is the host-type seam doing
      its job - the difference stays at the host layer.
- [ ] `hull diff` / `switch` / `doctor` green on the native host.
- **Milestone:** both host types green - the host-type seam (axiom C) is proven.

## Phase 7 - Retire Fedora

**Worth pulling forward.** Measured 2026-07-27: Fedora's virtual disk is **78.47 GB**
against NixOS's 9.04 GB, and running Fedora is also the trigger for the
`user@1000` failure (see HANDOVER). Retiring it is one action that reclaims ~78 GB
*and* removes the only error left on the machine - a bigger win than anything in
Phases 2–6. Nothing blocks it now that `claude-code` runs on NixOS; the
`hull-fedora` reference lives on GitHub, so the distro is not the quarry.

- [ ] Stop launching Fedora (immediate - no prerequisites).
- [ ] Once WSL and native are both proven, delete the Fedora Remix WSL distro.
- [ ] The Windows-side manual checklist (WezTerm, Hack Nerd Font, `.wezterm.lua`).

## Open questions to resolve as we go

- **Module interface design** - the exact options each module exposes. Deferred to Phase 6 - see the Phase 2 scope correction.
- **Registry ↔ flake wiring** - `github:<you>/registry` input vs a path override;
  must be portable (no hardcoded machine paths). Prerequisite: push the registry
  to a private remote (it has none yet). *Direction is settled (2026-07-28): hull
  takes registry as an input, not the reverse.* What remains open is the
  mechanism, and specifically how a private input authenticates during a rebuild
  run as root.
- **Secrets have a hard floor.** The Nix store is world-readable, so no token or
  private key can ever live in a Nix file. Confirmed 2026-07-28 that `sops`/
  `agenix` are the *wrong* tool for the `gh` token: those encrypt secrets that
  live in git, and this is per-machine state that must never enter git at all.
  They may still earn their place later for something genuinely shared.
- **Sharing a `lib/` pure function** between a NixOS/HM module and the CLI
  package - sound in principle, mechanism not yet verified.
- **Node / pnpm under NixOS** - pin via nix packages, not nvm/corepack (v1's
  deferred decision). Confirm on first `env` build.
- **Secrets** - SSH keys stay per-machine, generated by the lifecycle tool, never
  in Nix. Confirm no `sops`/`agenix` is needed yet.
- **Content audit** - for each `hull-fedora` config, decide carry-as-is vs
  re-derive. Some (locale/PATH shims) are foreign-host artifacts to drop.
