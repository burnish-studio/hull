# Handover — for an agent picking this up cold

Accurate as of **2026-07-28**, end of the Phase 2 switch-and-verify session.

## One-line state

Phase 1 and Phase 2 are **complete and live**. `modules/shell`, `modules/editor`
and `modules/tools` are activated on the running system (generation 10): zsh is
the login shell, all user packages resolve, and both out-of-store symlinks
resolve into the working tree. VS Code Remote-WSL connects, via `nix-ld`.

Phase 2 was **committed 2026-07-28** as the first commit ever authored from the
NixOS machine, using the identity decided that day.

### ⚠️ Start here

1. **Enable the two GitHub email-privacy settings** on both accounts — see the
   identity section below. Not done yet.
2. **Rename the Linux account `nixos` → `alx`** — cheapest while the home
   directory is still nearly empty, and safe now hull is pushed. Procedure below.
3. Then **Phase 3 — `git-identity`**, still gated on the registry having no
   GitHub remote.

If something is wrong, `sudo nixos-rebuild switch --rollback` returns you to
generation 9, the known-good pre-Phase-2 system.

## Identity — decided 2026-07-28

The pseudonym is **`alx`**, used consistently: git `user.name` on both accounts,
the Linux account name, and the handle everywhere else. It replaces the earlier
drift between "adam" and "alex" that the v1 registry still records.

**Three things get named, and conflating them was the old confusion:**

| | Same on both accounts? | Value |
| --- | --- | --- |
| GitHub **username** | no — globally unique | `burnish-studio`, `flintec-studio` |
| git **`user.name`** | **yes** | `alx` |
| git **`user.email`** | no — this *is* the routing | per-account noreply, below |

**Commit emails are the GitHub noreply addresses on both accounts:**

```
burnish-studio   5064093+burnish-studio@users.noreply.github.com
flintec-studio   102214117+flintec-studio@users.noreply.github.com
```

**Both are confirmed.** The burnish one was verified against `gh api user`
(2026-07-28), which also confirms `burnish-studio` is a **User** account, not an
organisation. The flintec one was confirmed by the captain the same day as
correct in the v1 `profile.nix`.

**Why noreply rather than an address on `burni.sh`** (the domain is owned, and
was considered): commit emails in public repositories are permanently public and
actively harvested, and are effectively unrevocable — rewriting history on a
public repo breaks every clone and fork. A noreply address **cannot receive mail
at all**, so harvesting it achieves nothing. It also needs no mail infrastructure
kept alive; the "durability" argument for a custom domain inverts the moment the
domain lapses. And it is not a one-way door — git email is configuration, so
switching later costs nothing and past commits simply keep the old address.

`alx@burni.sh` remains the right **human-facing contact address** for client
work. Contact email and commit email are different things with different
requirements; keeping them separate is what resolved the question.

**Two settings to enable on each GitHub account** (Settings → Emails):
*Keep my email addresses private* (also where the numeric id is shown), and
***Block command-line pushes that expose my email*** — the real safety net,
because it makes GitHub reject a misconfigured push rather than silently publish
a private address. Same philosophy as the generation cap: make the failure
impossible rather than remember not to trigger it.

`alex.g@flintec.com` must never reach a public commit. That setting enforces it.

### The identity is set repo-locally, and that is temporary

Set 2026-07-28 in `~/hull/.git/config` — **repo-local, not global**, and
explicitly a stopgap. Phase 3 generates it properly from the registry, at which
point this hand-set pair should be removed rather than left to conflict:
```bash
git config user.name  "alx"
git config user.email "5064093+burnish-studio@users.noreply.github.com"
```
Because it is repo-local, **`hull-fedora` and every other repo on this machine
still have no identity** and will fail to commit until Phase 3 lands or they are
configured the same way.

### ⚠️ Two machines can still push to this repo

Learned the hard way 2026-07-28: the first push from NixOS was **rejected**,
because the Fedora machine had pushed `d3bbf66` after this session's base commit.
Both sides had edited `HANDOVER.md`, so it needed a rebase and a manual conflict
resolution. Nothing was lost, but it cost time and could have lost content.

Fedora is still installed and can still commit. **Run `git pull` before starting
work**, and treat a rejected push as expected rather than alarming until Fedora
retires in Phase 7 — at which point this hazard disappears along with the
`user@1000` failure. One more reason that retirement is worth pulling forward.

**Related fragility found 2026-07-27, relevant to Phase 3:** the `gh auth login`
run wrote a credential helper into `~/.gitconfig` that hardcodes an absolute Nix
store path (`/nix/store/i9xqd3f37…-gh-2.96.0/bin/.gh-wrapped`). That path dies
the moment `gh` is updated and the old store path is garbage-collected, and
pushing breaks with no obvious cause. Phase 3 should generate the helper
declaratively as `helper = !${pkgs.gh}/bin/gh auth git-credential`, which Nix
keeps live.

## Read order

1. **this file** — state + how to work here
2. `README.md` — what hull is, in one screen
3. `docs/adr/0001`–`0006` — the decisions, each a standalone titled ADR
4. `ARCHITECTURE.md` — the target shape
5. `docs/how-it-works.md` — the machinery: flakes vs modules, evaluation vs
   activation, why module order does not matter. Read this before touching
   `flake.nix` or adding a module.
6. `CONTEXT.md` — the glossary / vocabulary
7. `ROADMAP.md` — **the plan ahead** (phases, milestones, open questions)

**This project does not use agent memory files.** Decided by the captain
2026-07-27: memories are invisible, unversioned and machine-local, which is
exactly wrong for a repo whose whole point is reproducibility. Everything
durable goes in these documents, where it shows up in a diff. If you find
yourself wanting to save a memory, write it here instead.

## Vocabulary change (2026-07-27): "panel" is retired

Older documents and ADRs 0002/0003 call a sealed concern module a **panel**. That
term is dropped — say **module**. It was a synonym that cost a translation step,
and "panel" already means a station's console interface in the wider system map.
The ADRs were left unedited as historical records. See `CONTEXT.md`.

## The two repos (do not confuse them)

| repo | what | edit? |
| --- | --- | --- |
| `hull` | **greenfield**, NixOS-native — this repo, the main hull going forward | yes |
| `hull-fedora` | **frozen v1** (Fedora + Home Manager, imperative bash) | **no — reference only** |

Paths differ by where you are working: on **NixOS** they are `~/hull` and
`~/hull-fedora`; on the legacy **Fedora** distro they are under
`~/burnish-studio/`. Both are on GitHub under `burnish-studio/`, so either can be
cloned anywhere. NixOS is the intended workplace — see "Working from NixOS".

`hull-fedora` is where you *mine* working content (neovim, wezterm, herdr,
starship, the git-identity logic, agent settings) and read the fuller metaphor
(`ARCHITECTURE.md` §1–7) and v1's decisions (`.plan/DECISIONS.md`, the `D1..`
log). Treat it as a quarry and a record — not as gospel; v1 had real bugs.

## Current system state (2026-07-28)

- **NixOS-WSL is installed** as a second WSL distro alongside Fedora Remix.
  Launch via Windows Terminal (NixOS tab) or `wsl -d NixOS` in PowerShell.
- **Hull flake is live**: `nixos-rebuild switch --flake github:burnish-studio/hull#wsl`
  drives the system. The repo is public at `github.com/burnish-studio/hull`.
- **`git`, `gh` and `claude-code` are on the machine** (verified 2026-07-27:
  `git` 2.54.0, `gh` 2.96.0, `claude-code` 2.1.220). **hull is developed from
  inside NixOS** — the first session run entirely from here was 2026-07-27.
  These are **system** packages, not user packages, on purpose: `sudo
  nixos-rebuild` runs as root and needs `git` to read a flake from a git repo.
- **Current user**: `nixos`, uid 1000 — a placeholder to be renamed to `alx`
  (see "Renaming the Linux account" below). Login shell is **zsh**, live since
  the Phase 2 switch on 2026-07-28.
- **Running generation is 10.** Generations 8, 9, 10 are held; the activation
  cap dropped 7 during the Phase 2 switch, observed in the switch output
  (`removing profile version 7`).
- **`nix-ld` is enabled**, so VS Code Remote-WSL works. See below.
- **Home Manager is wired in as a NixOS module** (`home-manager.nixosModules.
  home-manager`), not as v1's standalone `homeManagerConfiguration`. One
  `nixos-rebuild switch` activates system + user environment atomically, with one
  generation counter and one rollback.
- **`hosts/wsl.nix`** holds host config only: WSL settings, flakes, system
  packages, the unfree predicate, disk hygiene, the zsh login shell, and the
  home-manager block that imports the modules. No workarounds.
- **`modules/` is no longer empty** — `paths.nix`, `shell/`, `editor/`, `tools/`.
- **`flake.lock` is committed.** Three inputs track the **26.05 release line**:
  nixpkgs on `nixos-26.05` (the Hydra-tested channel branch — binaries are in the
  cache; `release-26.05` is the raw one and would mean source builds), nixos-wsl
  and home-manager both on `release-26.05`. The ref is the *update policy*; the
  lock supplies reproducibility. Do not point these at `main`/unstable without a
  reason — that is how a routine `nix flake update` pulls next-release code onto
  a 26.05 base.
- **One deliberate exception: `nixpkgs-unstable`.** It supplies exactly **two**
  packages, both justified in comments where they are used: `claude-code` (a
  Nix-installed binary cannot self-update and 26.05 goes stale in weeks) and
  `herdr` (verified absent from 26.05; present in unstable at 0.7.5). Never make
  unstable the default source. It reaches host modules as the `unstable`
  specialArg. Do not widen its use — take packages from it one at a time, each
  with a stated reason.
  **It has a standing disk cost:** a second full nixpkgs source tree, and one
  more for every revision fetched thereafter; only `nix-collect-garbage` clears
  the old ones. (Recorded figures disagree — 468 MB in the disk section below,
  478 MB when this was first noted on 2026-07-27. Re-measure before relying on
  either.)
- **Flakes are declared** in `hosts/wsl.nix`. `nixos-rebuild --flake` passes
  `--extra-experimental-features` itself (nixpkgs
  `pkgs/by-name/ni/nixos-rebuild-ng/src/nixos_rebuild/nix.py`), so rebuilds worked
  without this — but bare `nix` and the Phase 4 CLI need it declared.

## Working from NixOS — the rebuild workflow

hull is developed **on the machine it configures**. `git` and `claude-code` are
installed, so nothing needs bootstrapping any more.

**Setup is done (2026-07-27).** `~/hull` and `~/hull-fedora` are both cloned, and
`gh` is authenticated as **burnish-studio** over HTTPS with the git credential
helper configured, so push works without an SSH key. `hull` is public;
`hull-fedora` is private, which is why `gh auth` is needed for the quarry.

To reproduce on a fresh machine:
```bash
git clone https://github.com/burnish-studio/hull ~/hull      # public, no auth
gh auth login                                                # burnish-studio, HTTPS
git clone https://github.com/burnish-studio/hull-fedora ~/hull-fedora
```

**Two known papercuts, neither blocking:**
- `gh` warns *"Authentication credentials saved in plain text"* — the token sits
  unencrypted in `~/.config/gh/hosts.yml`. gh would use a secret service instead,
  but that needs a working user D-Bus session, which is exactly what the
  `user@1000` bug breaks. Acceptable for now (per-machine secret state, never in
  git); revisit if a keyring becomes available after Fedora retires.
- `gh auth login` cannot open a browser: `xdg-open,x-www-browser,wslview` not in
  PATH. Paste the URL manually. Fixing it properly would mean `wslu`/`wslview`,
  which shells out to Windows and so brushes the "hull never touches Windows"
  boundary — not worth an exception for a convenience.

### Authentication: what is declarative and what is not

Three separate things, and conflating them is how v1 went wrong:

| | Where it lives | When |
| --- | --- | --- |
| the **tool** (`gh`, `git`) | declarative, `hosts/wsl.nix` | done |
| the **credential** (token / SSH key) | per-machine secret, **never in Nix or git** | now, imperatively, by design |
| the **routing** (which account for which repo) | declarative, generated from the registry | Phase 3 |

So authenticating by hand now is *not* a violation — the roadmap already states
that keys stay per-machine and are never in Nix. What must not be hand-built is the
**routing**: no hand-written `~/.ssh/config` aliases, no hand-edited gitconfig
`includeIf` rules. Phase 3 generates those from the registry, and hand-made
versions would be regenerated (or worse, silently conflict).

**One account is enough for now.** Phase 2 only touches `hull` and `hull-fedora`,
both under `burnish-studio`. The second account matters when Phase 3 tests
multi-account routing. Expect Phase 3 to switch these remotes from HTTPS to the
SSH-alias form (`git@github-burnish:…`), as on the Fedora side — that is the
declarative routing arriving, not a mistake being corrected.

**Normal rebuild — always from the local path:**
```bash
sudo nixos-rebuild switch --flake ~/hull#wsl
```

Rebuilding from a path (not `github:…`) removes an entire class of failure: the
GitHub fetcher can serve a **cached older commit**, producing a build that
mysteriously lacks recent changes. If you ever must rebuild from GitHub, pass the
commit hash explicitly — `github:burnish-studio/hull/<hash>#wsl` — because the
fetcher cache is per-machine and cannot be trusted to have HEAD.

A local path also lets you test uncommitted work, subject to the git-tracking
gotcha below.

**Division of labour:** the agent edits, and runs `nix flake check`,
`nix build --dry-run` and `nixos-rebuild build` freely — all non-destructive. The
captain runs `nixos-rebuild switch` and makes the experiential calls.

**Gate before handing over a change:** `nix build --dry-run
.#nixosConfigurations.wsl.config.system.build.toplevel`. `nix flake check` is
*not* sufficient — it proves the config is well-formed but does not force package
derivations, so it misses unfree-licence and missing-package errors. This was
learned the hard way: `claude-code` was pushed in a state that failed to build
because only `flake check` had been run.

Better still, and free: run the real thing — `nixos-rebuild build --flake .#wsl`.
It is non-destructive (builds the system, activates nothing), it proves the whole
closure rather than predicting it, and it leaves a `./result` GC root so the
captain's `switch` is near-instant. Used for the Phase 2 handover.

**Do not trust the dry-run's "will be built" list as a cost estimate.** During
Phase 2 it listed `nodejs-22.23.1.drv` under "these derivations will be built",
implying a long source compile. It was wrong — `nix path-info --store
https://cache.nixos.org <outPath>` confirmed the output was substitutable, and
the real build fetched it. Check substitutability before believing you are about
to compile something big.

**Gotcha: flakes only see git-tracked files.** A new module is invisible until
`git add`ed. Committing is not required; staging is. The error reads "file does
not exist", which is misleading.

**Expect the `user@1000` exit 4 on every rebuild while Fedora runs.** It is the
documented upstream bug, not a regression. The fix is to stop starting Fedora.

## VS Code Remote-WSL, and `nix-ld` (added 2026-07-28)

**The symptom:** connecting VS Code to the NixOS distro failed with *"VS Code
Server for WSL closed unexpectedly"*, and the terminal showed
`Could not start dynamically linked executable: …/node` →
`NixOS cannot run dynamically linked executables intended for generic linux
environments`.

**The cause:** VS Code injects a server from the Windows side into
`~/.vscode-server-insiders/`, including a generic-linux prebuilt `node` that
requests the interpreter `/lib64/ld-linux-x86-64.so.2`. NixOS is not a
Filesystem Hierarchy Standard system, so that path holds **`stub-ld`** — a decoy
whose only job is to print exactly that error. Nothing was broken; VS Code simply
assumes a conventional Linux layout.

**The fix:** `programs.nix-ld.enable = true;` in `hosts/wsl.nix`. It replaces the
decoy with a real loader and supplies a base library set (libstdc++, zlib,
openssl, curl, systemd — see `nixos/modules/programs/nix-ld.nix` in nixpkgs),
which covers node. No extra `libraries` entries were needed.

**Verified live 2026-07-28:** `/lib64/ld-linux-x86-64.so.2` now resolves to
`…-nix-ld-2.0.6/libexec/nix-ld` rather than `…-stub-ld-…`, and VS Code connects.

**Why not `nix-community/nixos-vscode-server`**, the other common answer: it
patches the server binaries via a **systemd user service** — precisely what the
`user@1000` constraint below forbids depending on. `nix-ld` is a system-level
setting and is therefore immune. The documented constraint picked the winner.

**It does not breach "hull never touches Windows".** VS Code runs on the Windows
side and connects inward; hull only permits the injected binary to execute. Note
the server itself is downloaded imperatively and is **not** reproducible from
this repo — same category as lazy.nvim's plugins, an already-accepted compromise.

It lives at the host layer rather than in a module because `native` does not
exist yet, so there is no second consumer to design a seam for (ADR 0003).
Phase 6 should decide deliberately whether `native` wants it, not inherit it.

## What Nix owns, and what it must not

Asked directly 2026-07-28 — *"shouldn't everything inside the distro be set up
the proper Nix way, so hull reproduces the system fully?"* The goal is right, and
there is a real boundary. Three categories:

**(a) Configuration — Nix should own all of it.** Packages, dotfiles, shell,
editor, services. Anything here that gets set up by hand is a bug to fix. This is
where hull is already strong, and where the standard is absolute.

**(b) Secrets — Nix must never own these.** Not a limitation to work around; a
hard rule. **The Nix store is world-readable** — every file in `/nix/store` can
be read by every user and process on the machine. Putting a token or a private
key in a Nix file publishes it to the whole system *and* commits it to git. This
is the most common Nix beginner mistake. The roadmap's rule that SSH keys stay
per-machine and never enter Nix is correct and non-negotiable.

**(c) Runtime state — Nix cannot own these, and should not.** Caches, shell
history, nvim's cloned plugins, the VS Code server, session data. These are
*outputs of using the system*, not configuration. Declaring them is a category
error.

**Declarative does not mean stateless.** A rebuild swaps the system closure and
the Home-Manager-managed file set; it does **not** wipe `$HOME`. Home Manager
replaces the files it manages and leaves everything else alone. Kun's discipline
is that *configuration* has no ad-hoc component — not that the home directory is
erased on every build. Reading it the other way leads to chasing an impossible
target.

**So the `gh` token survives rebuilds indefinitely.** Rebuilds never touch
`~/.config/gh`. Re-authentication happens only if the token expires, is revoked,
or the file is deleted — never because you rebuilt. Same for SSH keys once
Phase 3 lands.

**The target end-state is small.** Once Phase 3 generates the git and ssh routing
declaratively, the irreducible per-machine secret state on this machine is **two
SSH private keys**. Everything else is either declared in hull or is disposable
cache. That is a reasonable definition of done.

**Considered and rejected: `impermanence`** (wipe the filesystem on boot, declare
what persists). It is the true maximalist answer, but it is awkward under WSL
where the virtual disk is managed by Windows, it introduces a whole new class of
failure, and it fights the out-of-store symlink design already committed to. Too
much complexity for a single-user development machine.

**Adopted instead:** `hull doctor` gains a **home-directory audit** in Phase 4 —
a declared list of expected paths, reporting anything in `$HOME` that hull does
not recognise. That converts "things are accumulating and I cannot tell what is
legitimate" into a checkable invariant. Same instinct as the generation cap:
don't police it by remembering; make the system report it.

## Renaming the Linux account `nixos` → `alx`

Not done yet. Recorded here because the mechanism is non-obvious and the ordering
matters.

**Why bother:** NixOS-WSL's installer creates `nixos` before hull exists, so the
bootstrap order guarantees a placeholder. A system that reproduces "to the
captain's liking" should not greet him as `nixos@nixos`. The registry already has
a `hosts.<name>.username` field designed to carry this.

**The mechanism is kinder than expected.** Linux records a numeric **uid** on
every file, not a name; the name is a lookup. The account is uid 1000, so if
`alx` is also uid 1000, every existing file transfers ownership automatically —
nothing needs `chown`. The scary part reduces to a `mv`.

```nix
users.users.alx.uid = 1000;   # same uid → existing files just work
wsl.defaultUser = "alx";      # regenerates /etc/wsl.conf
```
then rebuild, `mv /home/nixos /home/alx` from a root shell, and
`wsl --terminate NixOS` so the new `/etc/wsl.conf` takes effect.

**Three caveats:**
- You cannot rename an account you are logged into — do the move from
  `wsl -d NixOS -u root`.
- `users.mutableUsers` is `true`, so the old `nixos` account **lingers** until
  explicitly removed; it does not vanish on rebuild.
- `/etc/wsl.conf` also carries `hostname=nixos`, which hull does not currently
  set. Decide it deliberately rather than inheriting it.

**Do it after Phase 2 is pushed.** Once hull is on GitHub, the worst outcome of a
botched rename is re-cloning and re-authenticating `gh` — a few minutes. That is
the reproducibility claim being cashed in rather than asserted, and it is worth
testing deliberately while the home directory is still nearly empty. Treat it as
its own small session; it is the fiddliest step in the project so far.

## Disk and generations (policy decided 2026-07-27)

**Keep 3 system generations. Automatic** — `hosts/wsl.nix` caps them in
`system.activationScripts`, so every `nixos-rebuild switch` enforces the ceiling
however it was invoked. `auto-optimise-store` dedupes continuously. See ADR 0006
for the full reasoning; do not replace either with a timer.

**Verified live 2026-07-27.** After two rebuilds the profile holds exactly three
generations (6, 7, 8), the activation cap having dropped the older ones
unattended. The mechanism is confirmed by observation, not only by evaluation.

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

**Measured 2026-07-27, after the first manual collection** (904 store paths
deleted, 3.9 GiB freed, 7 generations → 3):

| | |
| --- | --- |
| Windows `C:` | **474.9 GB total, 59.4 GB free** (87.5% full) |
| NixOS guest | **3.8 GB used** (was 8.0 GB before collection); guest *claims* 952 GB free |
| NixOS `ext4.vhdx` | 9.04 GB — **so ~5 GB is now trapped**, see reclaim below |
| Fedora `ext4.vhdx` | **78.47 GB** — 20× the collected NixOS system |

**Re-measured after the Phase 2 build (2026-07-27, same day, guest side only):**
the store is **6.1 GB** and the guest reports **6.4 GB used** — up from 3.8 GB.
The Phase 2 closure (neovim, node, herdr, tree-sitter grammars, home-manager)
accounts for it: the build fetched 93 MiB compressed / 320 MiB unpacked on top of
an already-growing store. The Windows-side figures above were **not** re-measured
and are now stale by that much at least; the virtual disk only grows, so treat
9.04 GB as a floor, not a current reading. Re-measure from Windows before making
any disk decision.

**VS Code costs 675 MB, outside the Nix store (measured 2026-07-28).**
`~/.vscode-server-insiders` is the single largest thing in the home directory —
larger than the entire Phase 2 closure addition — and it is imperative,
non-reproducible, and permanent virtual-disk growth. Not an argument against
using VS Code; a number that belongs in any disk decision, because store
measurements (`du -sh /nix/store`) do not see it. Measure the home directory
separately: `du -sh ~/.[a-zA-Z]* | sort -rh | head`.

Headroom is **tight and moving**: the roadmap recorded 67.5 GB free on 2026-07-24,
so the NixOS install consumed ~8 GB in three days. Bounding growth is therefore
materially useful, not housekeeping — especially as Phase 2 adds neovim, node and
language servers.

Note the first collection freed **3.9 GB, not the 1–2 GB estimated** — accumulated
nixpkgs revisions and superseded generations were a bigger share than expected.
Hardlink dedup reported ≈0 saving immediately afterwards, which is expected: it
pays off as generations re-accumulate overlapping content, not on an empty store.

**The largest single win is still retiring Fedora (~78 GB — more than all remaining
free space), which also permanently silences the `user@1000` failure.** Deferred by
the captain 2026-07-27: it needs a migration pass first, so treat it as scheduled
work, not a quick cleanup.

Measure with `df -h /` and `du -sh /nix/store` on NixOS; list generations with
`ls -l /nix/var/nix/profiles/` (`nix-env -p` needs root even to read). Virtual disk
sizes are visible from Windows by walking
`HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss` for each distro's
`BasePath\ext4.vhdx` — unverified beyond the one run above.

**Losing old generations costs time, not recoverability** — hull is in git, so any
past system can be rebuilt from any commit. Generations only buy *instant*
rollback. Hence 3 rather than 10.

**Reclaim is now worth doing once.** The guest dropped to 3.8 GB but the virtual
disk is still 9.04 GB, so roughly **5 GB is trapped** — freed inside NixOS, not
returned to Windows. A WSL virtual disk grows but never shrinks on its own. To
recover it, from Windows:

```powershell
wsl --terminate NixOS
wsl --manage NixOS --set-sparse true    # recent WSL; else diskpart / Optimize-VHD
```

Check `wsl --manage --help` first — the flag is absent on older WSL builds. Per
hull's boundaries this stays a **manual Windows checklist item** alongside WezTerm
and fonts; hull never touches Windows. Once the activation-time cap is live (see
below), the ceiling should hold and this should not need repeating often.

## What is decided (see the ADRs for the reasoning)

- **0001** — target **NixOS exclusively**; two host types: `wsl` (NixOS-WSL) and
  `native` (NixOS on bare metal). WSL first, native once proven.
- **0002** — **segmentation**: identity-agnostic, host-type-aware; zero identity
  in the tool; multi-account baseline; opinions vs identity are separate axes.
- **0003** — **seam, not repo**: sealed modules (the ADR calls them "panels" —
  retired term, see above); split only on a real
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

**Constraint this places on the environment modules:** `systemd.user` services
work on a clean start, but will fail on any boot where Fedora was running. Until
Phase 7, do not make `shell` / `editor` / `tools` *depend* on Home Manager user
services. File-based config (zsh, neovim, git, starship) is unaffected either way
— prefer it. **As built, Phase 2 obeys this**: every module is file/package
config, no user services.

Note home-manager as a NixOS module does install a `home-manager-nixos.service`
(a system unit, not a user unit), so activation does not depend on the broken
user manager.

## Session log — 2026-07-27 (Phase 1 close-out)

What changed, so a fresh agent can see the delta rather than re-deriving it.

**Removed (the bulk of the value):**
- The `Delegate=no` / `DelegateSubgroup=` drop-in on `user@.service`. It never
  worked, and it wrongly attributed an upstream bug to hull's config.
- An anonymous inline module in `flake.nix` that set host config, contradicting
  `ARCHITECTURE.md`'s rule that host variation lives at the host layer. Moved into
  `hosts/wsl.nix`.
- The 2026-07-24 SIGCHLD root-cause claim, refuted by journal timestamps.

**Added:**
- `nixos-wsl` repinned from `main` → `release-26.05`, matching nixpkgs.
- Flakes declared in-config (rebuilds worked only because `nixos-rebuild` passes
  the flag itself; bare `nix` and the Phase 4 CLI need it declared).
- `git` and `claude-code` (unfree, allowed by name not blanket `allowUnfree`).
- Disk hygiene per ADR 0006.
- `docs/how-it-works.md` — flakes vs modules, evaluation vs activation.

**Verified:** zero-error baseline with both distros terminated, twice. Also a
reproducibility check — the same `nix.conf` store hash
(`n6qz6cc0ihib9y16g8vcl5c1kzazcsnj`) and the same system toplevel (`vhza8gd7…`)
were computed on Fedora and produced on NixOS independently.

**Two corrections worth remembering:**
- `nix flake check` passed a config that could not build (`claude-code`'s unfree
  licence). Only `nix build --dry-run` forces package derivations. Use it as the
  gate — this is why that rule is above.
- The first garbage collection freed 3.9 GB against a 1–2 GB estimate. Do not
  treat store growth estimates as reliable; measure.

## Session log — 2026-07-27 (Phase 2 build)

The first session run entirely from inside NixOS. Nothing was switched into; the
captain runs that.

**Decided:**
- **Drop the word "panel"** — see the vocabulary section at the top.
- **Split the planned `env` module into `shell` / `editor` / `tools`.** `env` was
  a grab-bag holding shell, editor, multiplexer, CLI tools and a language
  runtime, and it collided with the system map, where "the ship's body" is hull.
- **Phase 2 is porting, not interface design.** With one host consuming the
  modules there is nothing to design — options exist so a *second* consumer can
  differ, and `native` does not exist. Deferred to Phase 6. `ROADMAP.md` carries
  the full reasoning.
- **Out-of-store symlinks for nvim and herdr config**, store-managed for
  everything else. Reasoning in `ARCHITECTURE.md`.
- **No agent memory files on this project** — everything durable goes in these
  documents.

**Built:** `flake.nix` (home-manager input + NixOS module), `hosts/wsl.nix`
(zsh login shell, home-manager block), `modules/paths.nix`, `modules/shell`,
`modules/editor` (+ nvim lua copied from the quarry), `modules/tools`
(+ herdr config.toml).

**Dropped deliberately on port** — do not "restore" these, they were Fedora
artifacts:
- `glibcLocales` override + `LOCALE_ARCHIVE` + `LANG`. Verified on NixOS:
  `LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive` and
  `LANG=en_US.UTF-8` are already correct. v1 needed them only because Fedora is
  a foreign host.
- `home.sessionPath = [ "$HOME/.local/bin" ]`. That existed for v1's imperatively
  installed `hull` launcher; Phase 4's CLI is a Nix package.
- v1's `accountCommand` zsh function generator — that is git-identity, Phase 3.

**Verified by evaluation and by a real build (not switched):**
- `nixos-rebuild build --flake .#wsl` → `Done.`, exit 0.
- Login shell resolves to `zsh-5.9.1`.
- User packages resolve: fd, fzf, herdr 0.7.5, jq, lazygit, neovim 0.12.4,
  nodejs 22.23.1, ripgrep, starship, zsh.
- Both out-of-store links resolve into the working tree —
  `~/.config/nvim → /home/nixos/hull/modules/editor/nvim` and
  `~/.config/herdr/config.toml → /home/nixos/hull/modules/tools/herdr/config.toml`.
- `herdr` confirmed absent from 26.05, present in unstable at 0.7.5.

**Not verified — needs a human in the shell:** the prompt, autosuggestions,
keybindings, nvim actually launching and lazy.nvim fetching plugins, herdr
running. That is the first task of the next session.

**Correction worth remembering:** `nix build --dry-run` listed `nodejs-22.23.1`
under "these derivations will be built", implying a long source compile.
Substitutability checks and the real build both disproved it. The dry-run's
build/fetch split is not a reliable cost estimate.

## Session log — 2026-07-28 (Phase 2 switch, VS Code, identity)

**Switched into Phase 2.** `sudo nixos-rebuild switch --flake ~/hull#wsl`
completed `Done.` at exit 0. Two things in the output worth noting: `removing
profile version 7` (the generation cap firing unattended, first observation of it
during a real switch) and `restarting the following user units:
nixos-activation.service` — the user-unit step that normally fails, working,
because Fedora was not running.

**Verified live afterwards**, rather than by evaluation:
- Login shell is zsh; `nvim`, `herdr`, `starship`, `lazygit`, `fd`, `jq`, `node`
  all resolve from `/etc/profiles/per-user/nixos/bin/`.
- Both out-of-store symlinks resolve into the working tree. Note they are
  **two-hop** links (`~/.config/nvim` → `home-manager-files` → `hm_nvim` →
  `~/hull/modules/editor/nvim`), so a single `readlink` looks like it points into
  the store and is misleading. Use `readlink -f`.
- Generations 8, 9, 10 held.

**Added `programs.nix-ld.enable`** to fix VS Code Remote-WSL — full reasoning in
its own section above.

**Decided the identity** — `alx`, noreply emails on both accounts. Full reasoning
in its own section above. The burnish numeric id is verified against the API; the
flintec one is not.

**Reviewed the v1 registry** (`flake.nix` + `profile.nix`, pasted from the Fedora
machine). Three things must not carry over:
1. `hull.url = "path:/home/adam/burnish-studio/hull-fedora"` — an absolute path
   containing the old username, pointing at the frozen v1. This *is* "Gap C".
2. **The dependency direction is inverted.** v1 had registry depending on hull
   (registry's flake took hull as an input and called `hull.lib.mkHome`). The
   design in `ARCHITECTURE.md` has **hull taking registry as an input**, so
   registry becomes pure data. The flip is correct — hull produces
   `nixosConfigurations` and owns the hosts — and was confirmed by the captain
   2026-07-28.
3. `fullName = "alex"` with `hosts.wsl.username = "adam"` and
   `hosts.laptop.username = "alex"` — the exact naming drift `alx` resolves.

Worth keeping from it: the `accounts` structure, org/alias/key naming (matches
D1.5), and `default = true` on burnish.

**Inventoried the home directory.** Almost everything in it is imperative runtime
state written by tools, not by Nix — see "What Nix owns" above. `.copilot` is a
single lock file from a VS Code extension pushed in from the Windows side; the
captain did not ask for it and does not intend to use it. Uninstalling the
extension (or disabling it for the remote) stops it reappearing. Nothing to do on
the hull side.

## What is NOT done

- **The Linux account is still `nixos`** — rename to `alx` is planned, procedure
  recorded above.
- **The two GitHub email-privacy settings are not enabled yet** on either
  account. Until *Block command-line pushes that expose my email* is on, nothing
  structurally prevents a misconfigured repo from publishing a private address.
- **Git identity is repo-local to `~/hull` only** — every other repo on this
  machine, including `hull-fedora`, still cannot commit.
- **Module options are undesigned**, deliberately — Phase 6, when `native` shows
  what needs to vary.
- **nvim plugins are not reproducible.** `lua/plugin.lua` bootstraps lazy.nvim,
  which git-clones plugins into `~/.local/share/nvim` at runtime. The *config* is
  in hull; the *plugins* are not managed by Nix. First `nvim` launch needs
  network. This was true in v1 too — noted, not a regression.
- **`git-identity` (Phase 3) and `agents` (Phase 5) modules do not exist.**
- **Registry ↔ flake wiring** is unsolved (registry has no GitHub remote yet;
  must avoid v1's hardcoded-path "Gap C"). Note `modules/paths.nix` now solves
  the *same class* of problem for out-of-store links — reuse the pattern.
- **The `hull` CLI** does not exist yet (Phase 4).
- **The `alex` user** is not configured — current default user is `nixos`.
  Real user comes from the registry (Phase 3).
- **`hosts/native.nix`** does not exist — Phase 6.
- A NixOS minimal ISO is on a USB stick ready for the laptop (Phase 6 prep).
- **`claude-code` sits in `hosts/wsl.nix` temporarily** — it belongs in the
  `agents` module (Phase 5).
- **~5 GB is trapped in the WSL virtual disk** — one manual Windows-side
  compaction recovers it.
- **Fedora is still installed and holds 78.47 GB.** Retirement deferred by the
  captain 2026-07-27 pending a migration pass. Do not delete it unprompted.

## Immediate next step

1. **Set the git identity and commit Phase 2, then push** — values in the
   identity section above.
2. **Enable the two GitHub email-privacy settings** on both accounts, and verify
   the flintec numeric id while there.
3. **Rename `nixos` → `alx`** — procedure above. Its own small session.
4. **Then Phase 3 — `git-identity`.** This is the real deep-module work, and it
   is gated on one thing outside the code: **the registry has no GitHub remote.**
   Pushing it to a private repo is the prerequisite. Read the Phase 3
   carry-forward constraints in `ROADMAP.md` before designing anything — D1.3
   (port 443 unconditionally) and D1.5 (org-based naming) are non-obvious and
   were paid for once already.

**On mining `hull-fedora`:** a note in the previous handover said `home/` holds
only `AGENTS.md` and that everything is inline in a monolithic `home.nix`. That
is half right and was corrected 2026-07-27. `home/.config/` does hold tidy,
portable `nvim/`, `wezterm/` and `herdr/` configs — those copied across as files.
What *is* inline in `home.nix` is the git-identity logic (accounts → gitconfig
includes, URL rewrites, ssh blocks, the per-account shell functions), roughly
lines 9–104 and 165–196. That extraction is Phase 3's work — budget for it there,
not before.

## Working with the captain (alx)

- **He drives the terminal himself** via `! <cmd>` or his NixOS terminal tab
  for experiential / destructive steps (rebuilds, installs). You design and fix;
  he runs.
- **He wants to understand before approving.** Explain what/where/why; verify
  claims, don't assert.
- **Kun Chen's dotfiles are the reference** (github.com/kunchenguid/dotfiles).
  When you diverge, say so and justify it.
- **Minimalism first.** No bloat, no speculative features. If it's not needed
  yet, don't add it.
- **Write acronyms out in full** where a full version exists — "garbage
  collection", not "GC"; "Home Manager", not "HM". He should not have to guess
  at an abbreviation to read an explanation.
- **Don't add co-author lines to git commits** on this repo.

## Hard boundaries (do not cross)

- **hull never touches Windows.** No `/mnt` reads/writes, no `cmd.exe` /
  `powershell.exe`. The Windows-side setup (WezTerm, fonts) is a manual
  checklist. (The neovim `clip.exe` clipboard bridge is the one agreed
  exception, and lives in ported content.)
- **Company network drives** (`/mnt/d`, `/mnt/e`) must never be touched.

## Tooling note

**Corrected 2026-07-27.** A previous version of this file said project skills
(`/grill-with-docs` etc.) live in `hull-fedora/.claude/skills/`. They do not —
that clone has no `.claude/` directory; only `home/.claude/settings.json` and
`home/.claude/statusline-command.sh` are tracked. The skills were installed on
the Fedora machine via `npx` (Matt Pocock's set — grill-with-docs and the ADR
format) and were never committed anywhere. They are reinstallable from source, so
nothing is lost; do not go looking for them in the repo.

This repo's remote is `github.com/burnish-studio/hull` (public); `hull-fedora` is
at `github.com/burnish-studio/hull-fedora` (private, hence `gh auth`).
