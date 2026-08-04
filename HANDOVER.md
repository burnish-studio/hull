# Handover - for an agent picking this up cold

Accurate as of **2026-08-04**, end of the agent-tooling PATH session.

## One-line state

Phase 1 and Phase 2 are **complete, live and fully verified**. **Phase 5's wiring
is done**: `modules/agents` holds `claude-code`, `pi`, `python3`, the Claude Code
status line, and one `AGENTS.md` linked to both agents. What remains of Phase 5
is triggering the herdr integrations declaratively.

**The account rename is done.** The machine runs as `alx@wsl`, uid 1000, and
`/home/nixos` no longer exists. Verified after the switch: `id` gives
`uid=1000(alx) gid=100(users) groups=100(users),1(wheel)`, hostname `wsl`, login
shell zsh, and all **six** out-of-store symlinks resolve into `/home/alx/hull` -
nvim, herdr, Claude settings, Claude status line, and `AGENTS.md` to both
`~/.claude/CLAUDE.md` and `~/.pi/agent/AGENTS.md`. VS Code Remote-WSL connects,
via `nix-ld`.

Running **generation 14** (12, 13, 14 held; the switch dropped 11) at
`yrxd0p72dx5apj40jfwyx4p0xis3dj7w-nixos-system-wsl-26.05.20260722.b3fe958`. That
was byte-identical to the working tree's build at the end of the rename session.

**It is no longer: the tree is one un-switched change ahead** (2026-08-04). The
`home.sessionPath` addition in `modules/tools` builds clean as
`bfc54klc9fgb6bg5ihb26fl9p93wyxxf-nixos-system-wsl-26.05.20260722.b3fe958`, but
only the captain switches. Until he does, `~/.local/bin` is absent from PATH and
the agent tools installed there are invisible to any fresh shell. Separately,
`main` is one commit (`4ca04ad`) ahead of `origin/main` (`288d6b4`) - unpushed,
which the two-machines warning below cares about.

**Two rename follow-ups are still open** and are tasks 1 and 2 below: the herdr
Claude hook registration, and `~/.vscode-server-insiders`.

**Measured 2026-07-28 at close:** guest 8.2 GB used, store 7.0 GB,
`~/.vscode-server-insiders` 678 MB. Versions: git 2.54.0, gh 2.96.0, claude-code
2.1.220, pi 0.81.1, neovim 0.12.4, herdr 0.7.5, python 3.13.14. Not re-measured
2026-08-04 - treat the disk figures as a week stale.

### ⚠️ Start here

**First, the one action only the captain can take: `nixos-rebuild switch`.** The
tree holds a single built and verified un-switched change (`home.sessionPath`,
described above). Nothing else in this list is blocked on it, but the agent
tooling in `~/.local/bin` stays invisible to fresh shells until it lands.

**1. Re-register the herdr Claude hook - it currently fires at nothing.**
`modules/agents/claude/settings.json` still registers the `SessionStart` hook as
`bash '/home/nixos/.claude/hooks/herdr-agent-state.sh' session`, and that path no
longer exists. The script itself is fine and in the right place: `herdr
integration status` reports `claude: current (v7)` at
`/home/alx/.claude/hooks/herdr-agent-state.sh`. Only the registration is stale.

`herdr integration install claude` rewrites it, **but decide this first**: that
file is an out-of-store symlink into the working tree, so herdr writes through it
into hull, and the line it writes will contain `/home/alx`. That is an account
name in a public repo - a *second* ADR 0002 breach, not the same one as
`username = "alx"`. Three options, the captain's call:
- **Accept it**, consistent with the breach already taken, and let Phase 3 remove
  both together.
- **Reinstall, then hand-edit the path to `$HOME`** - which is exactly what the
  `statusLine` entry three lines below it already does, so the file would become
  self-consistent. This section used to say "do not hand-edit"; that is about
  *durability*, not danger. herdr only overwrites on the next reinstall, so the
  edit holds until then, and the reinstall is not routine.
- **Raise it with herdr upstream**, since `$HOME` is the portable form and this
  will bite anyone whose config is generated into a dotfiles repo.

`pi` needs no equivalent - verified 2026-07-28 that its extension is discovered
by directory, with no absolute path written anywhere.

**This got more expensive on 2026-08-04, and is no longer only cosmetic.** The
captain now runs firstmate on the **herdr** backend, and firstmate reads herdr's
native per-pane agent state (busy / idle / blocked) to supervise its workers.
That state is exactly what this hook feeds. With the registration dead, herdr
falls back to guessing from process detection - the weaker mechanism the
integration exists to replace - so firstmate supervises on degraded signal. Still
the captain's call between the three options, but it is now paying a real cost
rather than sitting idle.

**2. Delete `~/.vscode-server-insiders`** - 678 MB, and 11 files inside it still
reference `/home/nixos` (logs, caches, two copilot helpers), confirmed present
2026-07-28. VS Code re-injects it on the next connect. It is imperative,
non-reproducible state hull already disclaims, so rebuilding it is cheaper than
auditing it.

**3. Then compress this file.** It reached ~1400 lines on 2026-07-28 and is still
growing. The short rules were extracted to `AGENTS.md` at the repo root so a
newcomer is safe after 73 lines, which was the structural fix - but the state
document itself keeps growing, and some of it reads as archaeology already. The
session logs are the obvious candidate: they are append-only and the oldest carry
little that is not superseded. Correcting and shortening matters more here than
appending. Do it deliberately; there is load-bearing detail mixed into the
history.

**4. Then Phase 3 - `git-identity`**, still gated on one thing outside the code:
the registry has no GitHub remote. Read the collision warning below first. Note
the rename has already paid part of Phase 3's bill: `hosts/wsl.nix` now binds the
username once, so wiring the registry in is a one-line swap rather than a hunt.

**Closed 2026-07-28:** the GitHub email-privacy item. The captain confirmed both
noreply addresses are the ones already in use, taken from the accounts' own
settings pages. Worth one glance next time you are in there: *Block command-line
pushes that expose my email* is a **separate** tick from *Keep my email addresses
private*, and it is the one that actually rejects a bad push. `gh api user`
returns `email: null`, consistent with privacy being on; the block setting is not
exposed through the API, so it cannot be verified from here.

**Before touching anything: `git pull`.** The Fedora machine can still push to
this repo and has done so mid-session before. See "Two machines" below.

If something is wrong, `sudo nixos-rebuild switch --rollback` returns you to
generation 12 (agents module, before `AGENTS.md`); generation 11 predates `pi`
and `python3`.

### ⚠️ A collision is waiting in Phase 3

Home Manager **aborts activation** rather than overwrite a file it has no record
of creating. Hit for real this session: `~/.claude/settings.json` already existed
(Claude Code wrote it on first run), so the switch would have failed until the
file was removed. It was checked first - both its settings were carried into
hull's version - and then deleted.

**Phase 3 will hit this harder.** It manages `~/.gitconfig`, and that file
already exists with content you need: `gh auth login` wrote a credential helper
into it. Plan the migration rather than discovering it mid-switch. The general
alternative is `home-manager.backupFileExtension`, which renames the offender
instead of aborting; it was deliberately not adopted for a single one-off
collision, but it may earn its place when several land at once.

### ⚠️ Before closing shop

**Every session updates this file before it ends** (captain's instruction,
2026-07-28). This is not optional housekeeping - it is the mechanism the whole
project runs on. There are no agent memory files here, so a session that ends
without writing back has genuinely lost what it learned, and the next agent pays
to rediscover it. Several claims in this file were wrong until someone checked;
the cost of that is exactly what this rule exists to stop.

Work through these at the end of a session:

1. **The date and the state block** at the top - the commit `origin/main` is on,
   whether the tree is clean, the running generation.
2. **"Start here"** - re-order it for whoever comes next, and delete anything
   now done. A finished task must not sit here pretending to be pending.
3. **"What is NOT done"** - add what you discovered was missing, remove what you
   finished.
4. **A session log entry** - what changed, what was decided, and what you
   verified versus what you only evaluated. Follow the existing entries.
5. **Corrections** - if you found something in this file that was false, fix it
   where it lives *and* say so in the session log. A silent fix teaches nobody.
6. **Re-measure anything you quoted** - disk figures especially. They go stale
   within days and this file has carried contradictory numbers before.

7. **Leave the repo easier to pick up than you found it.** The captain's
   instruction, 2026-07-28, and it is standing rather than a one-off task:
   keeping hull clear, concise and quick to orient in is **every** agent's
   ongoing responsibility. If you had to dig for something the next person will
   also need, that is a documentation defect - fix it where it lives. Prefer
   correcting and shortening over appending. This file has grown steadily and a
   document nobody finishes reading protects nobody; the short rules now live in
   `AGENTS.md` at the repo root, which agent tools load automatically, precisely
   so a newcomer is not dependent on reading all of this first.

Then commit. Documentation changes ride along with the work that caused them,
unless the change is large enough to bury the diff - the house-style sweep was
its own commit for exactly that reason.

## Identity - decided 2026-07-28

The pseudonym is **`alx`**, used consistently: git `user.name` on both accounts,
the Linux account name, and the handle everywhere else. It replaces the earlier
drift between "adam" and "alex" that the v1 registry still records.

**Three things get named, and conflating them was the old confusion:**

| | Same on both accounts? | Value |
| --- | --- | --- |
| GitHub **username** | no - globally unique | `burnish-studio`, `flintec-studio` |
| git **`user.name`** | **yes** | `alx` |
| git **`user.email`** | no - this *is* the routing | per-account noreply, below |

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
actively harvested, and are effectively unrevocable - rewriting history on a
public repo breaks every clone and fork. A noreply address **cannot receive mail
at all**, so harvesting it achieves nothing. It also needs no mail infrastructure
kept alive; the "durability" argument for a custom domain inverts the moment the
domain lapses. And it is not a one-way door - git email is configuration, so
switching later costs nothing and past commits simply keep the old address.

`alx@burni.sh` remains the right **human-facing contact address** for client
work. Contact email and commit email are different things with different
requirements; keeping them separate is what resolved the question.

**Two settings to enable on each GitHub account** (Settings → Emails):
*Keep my email addresses private* (also where the numeric id is shown), and
***Block command-line pushes that expose my email*** - the real safety net,
because it makes GitHub reject a misconfigured push rather than silently publish
a private address. Same philosophy as the generation cap: make the failure
impossible rather than remember not to trigger it.

`alex.g@flintec.com` must never reach a public commit. That setting enforces it.

### The identity is set repo-locally, and that is temporary

Set 2026-07-28 in `~/hull/.git/config` - **repo-local, not global**, and
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
retires in Phase 7 - at which point this hazard disappears along with the
`user@1000` failure. One more reason that retirement is worth pulling forward.

**Related fragility found 2026-07-27, relevant to Phase 3:** the `gh auth login`
run wrote a credential helper into `~/.gitconfig` that hardcodes an absolute Nix
store path (`/nix/store/i9xqd3f37…-gh-2.96.0/bin/.gh-wrapped`). That path dies
the moment `gh` is updated and the old store path is garbage-collected, and
pushing breaks with no obvious cause. Phase 3 should generate the helper
declaratively as `helper = !${pkgs.gh}/bin/gh auth git-credential`, which Nix
keeps live.

## On a fresh machine: what hull does and does not do for you

Answered 2026-07-28, because "is it automatic?" is the first question anyone
asks and the answer was not written down anywhere.

**Automatic on `nixos-rebuild switch`** - one command, nothing else:
packages; zsh as the login shell; the nvim and herdr configs; Claude Code's
settings, status line and global instructions; pi's global instructions.
Home Manager creates the intermediate directories, so `~/.pi/agent/AGENTS.md`
is linked even though pi has never run. Those directories stay **real**, with
only the leaf file symlinked, so each tool can still write its own state
beside them (`auth.json`, herdr's sockets).

**Not automatic, and correctly so** - per-machine secret state, never in Nix
or git: `gh auth login`, pi's API keys in `~/.pi/agent/auth.json`, and (from
Phase 3) the SSH keys.

**Not automatic, and a gap worth closing:** the herdr agent integrations.
`herdr integration install claude` / `... pi` must be run by hand. hull declares
the packages and their dependencies but not the trigger. See the Phase 5 entry
in `ROADMAP.md`, including the constraint that the agent must have been run once
before its integration can install.

**Not automatic by design:** the Windows-side checklist - WezTerm, and the
JetBrainsMono Nerd Font the status line's glyphs need. hull never touches
Windows.

## Read order

0. **`AGENTS.md`** (repo root) - the rules, in one screen. Agent tools load it
   automatically, so you may already have it. `CLAUDE.md` is a symlink to it.
1. **this file** - state + how to work here
2. `README.md` - what hull is, in one screen
3. `docs/adr/0001`–`0006` - the decisions, each a standalone titled ADR
4. `ARCHITECTURE.md` - the target shape
5. `docs/how-it-works.md` - the machinery: flakes vs modules, evaluation vs
   activation, why module order does not matter. Read this before touching
   `flake.nix` or adding a module.
6. `CONTEXT.md` - the glossary / vocabulary
7. `ROADMAP.md` - **the plan ahead** (phases, milestones, open questions)

**This project does not use agent memory files.** Decided by the captain
2026-07-27: memories are invisible, unversioned and machine-local, which is
exactly wrong for a repo whose whole point is reproducibility. Everything
durable goes in these documents, where it shows up in a diff. If you find
yourself wanting to save a memory, write it here instead.

## Vocabulary change (2026-07-27): "panel" is retired

Older documents and ADRs 0002/0003 call a sealed concern module a **panel**. That
term is dropped - say **module**. It was a synonym that cost a translation step,
and "panel" already means a station's console interface in the wider system map.
The ADRs were left unedited as historical records. See `CONTEXT.md`.

## The three repos on this machine (do not confuse them)

| repo | what | edit? |
| --- | --- | --- |
| `~/hull` | **greenfield**, NixOS-native - this repo, the main hull going forward | yes |
| `~/hull-fedora` | **frozen v1** (Fedora + Home Manager, imperative bash) | **no - reference only** |
| `~/dotfiles` | **Kun Chen's dotfiles**, cloned 2026-07-28 - the upstream reference (macOS / nix-darwin) | **no - read only** |

Paths differ by where you are working: on **NixOS** they are `~/hull` and
`~/hull-fedora`; on the legacy **Fedora** distro they are under
`~/burnish-studio/`. Both are on GitHub under `burnish-studio/`, so either can be
cloned anywhere. NixOS is the intended workplace - see "Working from NixOS".

`hull-fedora` is where you *mine* working content (neovim, wezterm, herdr,
starship, the git-identity logic, agent settings) and read the fuller metaphor
(`ARCHITECTURE.md` §1–7) and v1's decisions (`.plan/DECISIONS.md`, the `D1..`
log). Treat it as a quarry and a record - not as gospel; v1 had real bugs.

## Reviewed against Kun's dotfiles (2026-07-28)

A full read of `~/dotfiles`. Recorded so it does not need repeating.

**Its shape:** three Nix files (`flake.nix`, `configuration.nix`, `home.nix`),
flat - no `modules/` and no `hosts/`. Plus `bootstrap.sh`, `rebuild.sh`, and a
`home/` tree holding the nvim / wezterm / herdr / claude configs.

**So hull is *more* structured than its reference, not less.** That is earned -
Kun targets one Mac, hull targets two host types - but README's "the overall
structure is adapted from Kun Chen's dotfiles" overstates it. The **content** is
closely derived (the zsh block, starship settings, aliases and the nvim lua are
near-identical); the **structure** is hull's own.

**Three places hull diverges and is right. Do not "fix" these back:**
1. **`~/.dotfiles` hardcoding.** Kun derives every out-of-store path from
   `${config.home.homeDirectory}/.dotfiles`, and `rebuild.sh` runs
   `ln -sfn "$DIR" ~/.dotfiles` on every invocation to keep that true. That
   symlink dance *is* the "Gap C" pattern. `hull.repoPath` removes the need.
2. **Unfree licensing.** Kun sets `nixpkgs.config.allowUnfree = true` - blanket.
   hull names `claude-code` in a predicate, so a future unfree dependency cannot
   arrive unnoticed.
3. **The herdr symlink.** Kun links the whole `.config/herdr` **directory**. hull
   links only `config.toml`, because herdr writes sockets and session state into
   that directory and a socket inside the repo makes the path uncopyable by Nix,
   breaking every build. hull found a real bug in the pattern.

**One place hull was behind:** `lazy-lock.json` - now fixed, see the nvim entry
under "What is NOT done".

**"Stripping the old with the new"** - the captain's recollection of Kun's
declarative discipline is `homebrew.onActivation.cleanup = "zap"`, which removes
any Homebrew package not listed in the config. It is a **Homebrew** mechanism and
macOS-only. There is no NixOS equivalent to add, because the system profile
already contains exactly what is declared; nothing accumulates to zap. hull has
that property for free. Kun needs the line precisely because Homebrew is the
imperative escape hatch in his setup.

**Mine this for Phase 5 (`agents`):** `home/.claude/settings.json` (theme plus a
statusline command printing model name and context-window usage), and the
one-source-three-targets pattern - a single `home/AGENTS.md` linked to
`.claude/CLAUDE.md`, `.codex/AGENTS.md` and `.config/opencode/AGENTS.md`. His
AGENTS.md is 15 terse lines. Two rules are already hull convention. **One is not:
"Never use the em dash."** hull's documents use them throughout, so adopt that
rule deliberately or not at all - do not import the file wholesale.

**Mine this for Phase 6 (`native`):** `home/.config/wezterm/wezterm.lua`, and
font management via `nerd-fonts.hack` + `fonts.fontconfig.enable`. Both are
Windows-side manual checklist items on WSL; on `native` they become declarative.

**Not adopted: continuous integration.** Kun's only GitHub workflow auto-closes
pull requests (a personal-repo policy) - he runs **no** build check in CI. A
workflow running `nixos-rebuild build` on push would have caught the one bad
`claude-code` push, but for a solo repo where the local gate is run reliably the
marginal value is low and it adds a third-party action dependency. Revisit only
if pushing-from-one-machine-and-rebuilding-on-another becomes routine.

## Current system state (2026-07-28)

- **NixOS-WSL is installed** as a second WSL distro alongside Fedora Remix.
  Launch via Windows Terminal (NixOS tab) or `wsl -d NixOS` in PowerShell.
- **Hull flake is live**: `nixos-rebuild switch --flake github:burnish-studio/hull#wsl`
  drives the system. The repo is public at `github.com/burnish-studio/hull`.
- **`git`, `gh` and `claude-code` are on the machine** (verified 2026-07-27:
  `git` 2.54.0, `gh` 2.96.0, `claude-code` 2.1.220). **hull is developed from
  inside NixOS** - the first session run entirely from here was 2026-07-27.
  These are **system** packages, not user packages, on purpose: `sudo
  nixos-rebuild` runs as root and needs `git` to read a flake from a git repo.
- **Current user**: `alx`, uid 1000, hostname `wsl` - renamed from the `nixos`
  placeholder on 2026-07-28. Login shell is **zsh**, live since the Phase 2
  switch on 2026-07-28.
- **Running generation is 14.** Generations 12, 13, 14 are held; the activation
  cap dropped 11 during the rename switch, observed in the switch output
  (`removing profile version 11`).
- **`nix-ld` is enabled**, so VS Code Remote-WSL works. See below.
- **Home Manager is wired in as a NixOS module** (`home-manager.nixosModules.
  home-manager`), not as v1's standalone `homeManagerConfiguration`. One
  `nixos-rebuild switch` activates system + user environment atomically, with one
  generation counter and one rollback.
- **`hosts/wsl.nix`** holds host config only: WSL settings, flakes, system
  packages, the unfree predicate, disk hygiene, the zsh login shell, and the
  home-manager block that imports the modules. No workarounds.
- **`modules/` is no longer empty** - `paths.nix`, `shell/`, `editor/`, `tools/`,
  `agents/`.
- **`claude-code` is a USER package now**, in `modules/agents`, not a system
  package in `hosts/wsl.nix`. The host file's reason for system packages - `sudo
  nixos-rebuild` runs as root and needs `git` to read a flake from a git repo -
  never applied to it. `git` and `gh` stay system packages for that reason.
- **The terminal font is JetBrainsMono Nerd Font** (decided 2026-07-28), installed
  Windows-side by hand. It renders the status line's Plane-15 glyphs correctly,
  verified live. Phase 6 should use `nerd-fonts.jetbrains-mono` for `native` so
  both host types agree - note the ported `wezterm.lua` still says `Hack Nerd
  Font`, which is Kun's choice describing the laptop, and should change with it.
- **`flake.lock` is committed.** Three inputs track the **26.05 release line**:
  nixpkgs on `nixos-26.05` (the Hydra-tested channel branch - binaries are in the
  cache; `release-26.05` is the raw one and would mean source builds), nixos-wsl
  and home-manager both on `release-26.05`. The ref is the *update policy*; the
  lock supplies reproducibility. Do not point these at `main`/unstable without a
  reason - that is how a routine `nix flake update` pulls next-release code onto
  a 26.05 base.
- **One deliberate exception: `nixpkgs-unstable`.** It supplies exactly **two**
  packages, both justified in comments where they are used: `claude-code` (a
  Nix-installed binary cannot self-update and 26.05 goes stale in weeks) and
  `herdr` (verified absent from 26.05; present in unstable at 0.7.5). Never make
  unstable the default source. It reaches host modules as the `unstable`
  specialArg. Do not widen its use - take packages from it one at a time, each
  with a stated reason.
  **It has a standing disk cost:** a second full nixpkgs source tree, and one
  more for every revision fetched thereafter; only `nix-collect-garbage` clears
  the old ones. (Recorded figures disagree - 468 MB in the disk section below,
  478 MB when this was first noted on 2026-07-27. Re-measure before relying on
  either.)
- **Flakes are declared** in `hosts/wsl.nix`. `nixos-rebuild --flake` passes
  `--extra-experimental-features` itself (nixpkgs
  `pkgs/by-name/ni/nixos-rebuild-ng/src/nixos_rebuild/nix.py`), so rebuilds worked
  without this - but bare `nix` and the Phase 4 CLI need it declared.

## Working from NixOS - the rebuild workflow

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
- `gh` warns *"Authentication credentials saved in plain text"* - the token sits
  unencrypted in `~/.config/gh/hosts.yml`. gh would use a secret service instead,
  but that needs a working user D-Bus session, which is exactly what the
  `user@1000` bug breaks. Acceptable for now (per-machine secret state, never in
  git); revisit if a keyring becomes available after Fedora retires.
- `gh auth login` cannot open a browser: `xdg-open,x-www-browser,wslview` not in
  PATH. Paste the URL manually. Fixing it properly would mean `wslu`/`wslview`,
  which shells out to Windows and so brushes the "hull never touches Windows"
  boundary - not worth an exception for a convenience.

### Authentication: what is declarative and what is not

Three separate things, and conflating them is how v1 went wrong:

| | Where it lives | When |
| --- | --- | --- |
| the **tool** (`gh`, `git`) | declarative, `hosts/wsl.nix` | done |
| the **credential** (token / SSH key) | per-machine secret, **never in Nix or git** | now, imperatively, by design |
| the **routing** (which account for which repo) | declarative, generated from the registry | Phase 3 |

So authenticating by hand now is *not* a violation - the roadmap already states
that keys stay per-machine and are never in Nix. What must not be hand-built is the
**routing**: no hand-written `~/.ssh/config` aliases, no hand-edited gitconfig
`includeIf` rules. Phase 3 generates those from the registry, and hand-made
versions would be regenerated (or worse, silently conflict).

**One account is enough for now.** Phase 2 only touches `hull` and `hull-fedora`,
both under `burnish-studio`. The second account matters when Phase 3 tests
multi-account routing. Expect Phase 3 to switch these remotes from HTTPS to the
SSH-alias form (`git@github-burnish:…`), as on the Fedora side - that is the
declarative routing arriving, not a mistake being corrected.

**Normal rebuild - always from the local path:**
```bash
sudo nixos-rebuild switch --flake ~/hull#wsl
```

Rebuilding from a path (not `github:…`) removes an entire class of failure: the
GitHub fetcher can serve a **cached older commit**, producing a build that
mysteriously lacks recent changes. If you ever must rebuild from GitHub, pass the
commit hash explicitly - `github:burnish-studio/hull/<hash>#wsl` - because the
fetcher cache is per-machine and cannot be trusted to have HEAD.

A local path also lets you test uncommitted work, subject to the git-tracking
gotcha below.

**Division of labour:** the agent edits, and runs `nix flake check`,
`nix build --dry-run` and `nixos-rebuild build` freely - all non-destructive. The
captain runs `nixos-rebuild switch` and makes the experiential calls.

**Gate before handing over a change:** `nix build --dry-run
.#nixosConfigurations.wsl.config.system.build.toplevel`. `nix flake check` is
*not* sufficient - it proves the config is well-formed but does not force package
derivations, so it misses unfree-licence and missing-package errors. This was
learned the hard way: `claude-code` was pushed in a state that failed to build
because only `flake check` had been run.

Better still, and free: run the real thing - `nixos-rebuild build --flake .#wsl`.
It is non-destructive (builds the system, activates nothing), it proves the whole
closure rather than predicting it, and it leaves a `./result` GC root so the
captain's `switch` is near-instant. Used for the Phase 2 handover.

**Do not trust the dry-run's "will be built" list as a cost estimate.** During
Phase 2 it listed `nodejs-22.23.1.drv` under "these derivations will be built",
implying a long source compile. It was wrong - `nix path-info --store
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
Filesystem Hierarchy Standard system, so that path holds **`stub-ld`** - a decoy
whose only job is to print exactly that error. Nothing was broken; VS Code simply
assumes a conventional Linux layout.

**The fix:** `programs.nix-ld.enable = true;` in `hosts/wsl.nix`. It replaces the
decoy with a real loader and supplies a base library set (libstdc++, zlib,
openssl, curl, systemd - see `nixos/modules/programs/nix-ld.nix` in nixpkgs),
which covers node. No extra `libraries` entries were needed.

**Verified live 2026-07-28:** `/lib64/ld-linux-x86-64.so.2` now resolves to
`…-nix-ld-2.0.6/libexec/nix-ld` rather than `…-stub-ld-…`, and VS Code connects.

**Why not `nix-community/nixos-vscode-server`**, the other common answer: it
patches the server binaries via a **systemd user service** - precisely what the
`user@1000` constraint below forbids depending on. `nix-ld` is a system-level
setting and is therefore immune. The documented constraint picked the winner.

**It does not breach "hull never touches Windows".** VS Code runs on the Windows
side and connects inward; hull only permits the injected binary to execute. Note
the server itself is downloaded imperatively and is **not** reproducible from
this repo - same category as lazy.nvim's plugins, an already-accepted compromise.

It lives at the host layer rather than in a module because `native` does not
exist yet, so there is no second consumer to design a seam for (ADR 0003).
Phase 6 should decide deliberately whether `native` wants it, not inherit it.

**Nix syntax highlighting in VS Code** (asked 2026-07-28): the extension is
**Nix IDE** (`jnoortheen.nix-ide`). Highlighting works with no configuration.

There is a clean split worth preserving here. The **extension** is a VS Code
artifact - installed from the Windows side, pushed into the remote, landing in
`~/.vscode-server-insiders/extensions/`, and **not** Nix-managed. But if the
full language-server experience is ever wanted (completion, go-to-definition,
inline errors), the **server** is `nixd` or `nil`, and those are Nix packages
that belong in hull - probably `modules/editor`. Editor plugin imperative, tool
declarative. Do not install a language server by hand; add it to the module.
Not needed for highlighting alone, so it has not been added.

## What Nix owns, and what it must not

Asked directly 2026-07-28 - *"shouldn't everything inside the distro be set up
the proper Nix way, so hull reproduces the system fully?"* The goal is right, and
there is a real boundary. Three categories:

**(a) Configuration - Nix should own all of it.** Packages, dotfiles, shell,
editor, services. Anything here that gets set up by hand is a bug to fix. This is
where hull is already strong, and where the standard is absolute.

**(b) Secrets - Nix must never own these.** Not a limitation to work around; a
hard rule. **The Nix store is world-readable** - every file in `/nix/store` can
be read by every user and process on the machine. Putting a token or a private
key in a Nix file publishes it to the whole system *and* commits it to git. This
is the most common Nix beginner mistake. The roadmap's rule that SSH keys stay
per-machine and never enter Nix is correct and non-negotiable.

**(c) Runtime state - Nix cannot own these, and should not.** Caches, shell
history, nvim's cloned plugins, the VS Code server, session data. These are
*outputs of using the system*, not configuration. Declaring them is a category
error.

**Declarative does not mean stateless.** A rebuild swaps the system closure and
the Home-Manager-managed file set; it does **not** wipe `$HOME`. Home Manager
replaces the files it manages and leaves everything else alone. Kun's discipline
is that *configuration* has no ad-hoc component - not that the home directory is
erased on every build. Reading it the other way leads to chasing an impossible
target.

**So the `gh` token survives rebuilds indefinitely.** Rebuilds never touch
`~/.config/gh`. Re-authentication happens only if the token expires, is revoked,
or the file is deleted - never because you rebuilt. Same for SSH keys once
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

**Adopted instead:** `hull doctor` gains a **home-directory audit** in Phase 4 -
a declared list of expected paths, reporting anything in `$HOME` that hull does
not recognise. That converts "things are accumulating and I cannot tell what is
legitimate" into a checkable invariant. Same instinct as the generation cap:
don't police it by remembering; make the system report it.

## The account rename `nixos` → `alx` (done 2026-07-28)

**History, kept short.** NixOS-WSL's installer creates `nixos` before hull
exists, so the bootstrap order guaranteed a placeholder. It was renamed on
2026-07-28: `hosts/wsl.nix` binds `username = "alx"` once in a `let` and uses it
at all three sites (`wsl.defaultUser`, the login shell, the Home Manager user),
and `networking.hostName = "wsl"` is declared rather than inherited. Phase 3
turns that one binding into `registry.hosts.wsl.username` and the ADR 0002 breach
goes with it.

The mechanism was kinder than expected: Linux records a numeric **uid** on every
file, not a name, and NixOS-WSL declares `uid = mkDefault 1000` for whoever
`wsl.defaultUser` names. So `alx` inherited uid 1000, every file transferred
ownership with no `chown`, and the whole thing reduced to `mv /home/nixos
/home/alx` followed by activating the pre-built closure. `hull.repoPath` derives
from `home.homeDirectory`, so all six out-of-store symlinks re-pointed with no
path edits - `modules/paths.nix` earning its keep.

### The one lesson that outlives the rename

**`nixos-rebuild switch --flake` fails from a root login.** Nix reads the flake
through **libgit2**, which refuses a repository owned by another uid (`error code
= 7`). Under `sudo` it works, because libgit2 honours `SUDO_UID` - which is why
the normal workflow never hits this, and why it will ambush you the first time
you work from `wsl -u root`. `GIT_CONFIG_COUNT` env overrides do **not** help:
that is a git-CLI feature libgit2 does not implement. What does work: a real
`[safe] directory` entry in `/root/.gitconfig`, or `SUDO_UID=1000` in the
environment, or - as used here - skip the flake entirely and activate a
pre-built closure by store path:

```bash
nix-env -p /nix/var/nix/profiles/system --set /nix/store/<path>-nixos-system-wsl-…
/nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

That is what `nixos-rebuild switch` does internally, split in two. The `nix-env
--set` is what records a generation; `switch-to-configuration` alone activates
without one, which breaks rollback and the generation cap.

### What testing corrected, and why it matters

The procedure sat in this file as recorded fact from 2026-07-27, and **three of
its steps were wrong** - plus the libgit2 problem, which was not in it at all:

- It claimed the old account lingers under `mutableUsers` and needs explicit
  removal. It does not: `update-users-groups.pl` removes a *previously declared*
  user and rewrites `/etc/passwd` in one pass, so there is never a window with
  two accounts on uid 1000. Removal is omission from `/etc/passwd` only - the
  script never deletes a home directory.
- It prescribed `users.users.alx.uid = 1000`, a redundant restatement of the
  NixOS-WSL `mkDefault`.
- It gave the order as rebuild *then* `mv`. That is backwards: `createHome` is
  `true`, so switching first creates an empty `/home/alx` and the `mv` nests the
  real home as `/home/alx/nixos`.

**Every one was invisible to reading and obvious to testing** - `dry-activate`
reported the user removal, one `nix eval` settled `createHome`, and a five-second
`sudo env -u SUDO_UID` reproduced the libgit2 refusal. A procedure written from
documentation and never rehearsed is a draft. That is the generalisable lesson,
and it is why the rehearsal session was worth its cost.
## Disk and generations (policy decided 2026-07-27)

**Keep 3 system generations. Automatic** - `hosts/wsl.nix` caps them in
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
for the same reason - it bounds the average, not the peak.

Generations are cheap: the store is content-addressed, so generations sharing the
same nixpkgs revision differ only by what changed. Note the store also holds every
nixpkgs revision ever fetched (~468 MB each), which only `nix-collect-garbage`
clears - so "3 generations" is not the whole footprint.

**Measured 2026-07-27, after the first manual collection** (904 store paths
deleted, 3.9 GiB freed, 7 generations → 3):

| | |
| --- | --- |
| Windows `C:` | **474.9 GB total, 59.4 GB free** (87.5% full) |
| NixOS guest | **3.8 GB used** (was 8.0 GB before collection); guest *claims* 952 GB free |
| NixOS `ext4.vhdx` | 9.04 GB - **so ~5 GB is now trapped**, see reclaim below |
| Fedora `ext4.vhdx` | **78.47 GB** - 20× the collected NixOS system |

**Re-measured after the Phase 2 build (2026-07-27, same day, guest side only):**
the store is **6.1 GB** and the guest reports **6.4 GB used** - up from 3.8 GB.
The Phase 2 closure (neovim, node, herdr, tree-sitter grammars, home-manager)
accounts for it: the build fetched 93 MiB compressed / 320 MiB unpacked on top of
an already-growing store. The Windows-side figures above were **not** re-measured
and are now stale by that much at least; the virtual disk only grows, so treat
9.04 GB as a floor, not a current reading. Re-measure from Windows before making
any disk decision.

**Re-measured 2026-07-28 (guest side, end of the style-sweep session):** the
store is **6.3 GB** and the guest reports **7.3 GB used**. So the store grew
~200 MB and the guest ~900 MB in a day, on a session that added no packages at
all - the difference is `nixos-rebuild build` leaving a `./result` closure plus
ordinary cache and VS Code server growth. Worth knowing before attributing
growth to whatever the session happened to be doing.

**VS Code costs 678 MB, outside the Nix store (measured 2026-07-28, unchanged
within a day at 675-678 MB).** `~/.vscode-server-insiders` is the single largest
thing in the home directory - larger than the entire Phase 2 closure addition -
and it is imperative, non-reproducible, and permanent virtual-disk growth. Not an
argument against using VS Code; a number that belongs in any disk decision,
because store measurements (`du -sh /nix/store`) do not see it. Measure the home
directory separately: `du -sh ~/.[a-zA-Z]* | sort -rh | head`.

Headroom is **tight and moving**: the roadmap recorded 67.5 GB free on 2026-07-24,
so the NixOS install consumed ~8 GB in three days. Bounding growth is therefore
materially useful, not housekeeping - especially as Phase 2 adds neovim, node and
language servers.

Note the first collection freed **3.9 GB, not the 1–2 GB estimated** - accumulated
nixpkgs revisions and superseded generations were a bigger share than expected.
Hardlink dedup reported ≈0 saving immediately afterwards, which is expected: it
pays off as generations re-accumulate overlapping content, not on an empty store.

**The largest single win is still retiring Fedora (~78 GB - more than all remaining
free space), which also permanently silences the `user@1000` failure.** Deferred by
the captain 2026-07-27: it needs a migration pass first, so treat it as scheduled
work, not a quick cleanup.

Measure with `df -h /` and `du -sh /nix/store` on NixOS; list generations with
`ls -l /nix/var/nix/profiles/` (`nix-env -p` needs root even to read). Virtual disk
sizes are visible from Windows by walking
`HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss` for each distro's
`BasePath\ext4.vhdx` - unverified beyond the one run above.

**Losing old generations costs time, not recoverability** - hull is in git, so any
past system can be rebuilt from any commit. Generations only buy *instant*
rollback. Hence 3 rather than 10.

**Reclaim is now worth doing once.** The guest dropped to 3.8 GB but the virtual
disk is still 9.04 GB, so roughly **5 GB is trapped** - freed inside NixOS, not
returned to Windows. A WSL virtual disk grows but never shrinks on its own. To
recover it, from Windows:

```powershell
wsl --terminate NixOS
wsl --manage NixOS --set-sparse true    # recent WSL; else diskpart / Optimize-VHD
```

Check `wsl --manage --help` first - the flag is absent on older WSL builds. Per
hull's boundaries this stays a **manual Windows checklist item** alongside WezTerm
and fonts; hull never touches Windows. Once the activation-time cap is live (see
below), the ceiling should hold and this should not need repeating often.

## What is decided (see the ADRs for the reasoning)

- **0001** - target **NixOS exclusively**; two host types: `wsl` (NixOS-WSL) and
  `native` (NixOS on bare metal). WSL first, native once proven.
- **0002** - **segmentation**: identity-agnostic, host-type-aware; zero identity
  in the tool; multi-account baseline; opinions vs identity are separate axes.
- **0003** - **seam, not repo**: sealed modules (the ADR calls them "panels" -
  retired term, see above); split only on a real
  second consumer; registry is the data-exception.
- **0004** - **CLI**: thin wrappers + imperative substance; `writeShellApplication`.
- **0005** - clean-start rewrite; v1 frozen as `hull-fedora`.
- **0006** - **disk hygiene is event-driven on WSL**: the guest sees a fake ~1 TB
  of free space so pressure-driven GC never fires, and the virtual disk never
  shrinks. Cap generations at activation, dedupe continuously, reclaim in the CLI.
  Not inherited by `native`.

## Known issue: `user@1000.service` fails - one root cause, three symptoms

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
running - `systemctl status` shows ~19 tasks in a populated cgroup, and
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
evidence is *more specific* than any upstream report - none of them diagnose the
cgroup layer. Two independent sources correlate it with **another WSL distro
already running**: NixOS-WSL #888 (labelled `upstream-bug`) and WSL #40590, where
it fails "when launching multiple instances sequentially" (`vm_4` fails, `vm_3`
succeeds, identical configs). Intermittency is characteristic - repeat any test
at least twice before believing the result.

**Relevant issues:**
- https://github.com/nix-community/NixOS-WSL/issues/888
- https://github.com/microsoft/WSL/issues/40590 (closed, not planned)
- https://github.com/microsoft/WSL/issues/13564
- https://github.com/microsoft/WSL/issues/13826#issuecomment-3996921259

**CONFIRMED 2026-07-27.** With **both distros terminated** and NixOS opened alone,
twice: no banner, `systemctl --failed` → `0 loaded units listed`, and
`nixos-rebuild switch` completes with `Done.` - no warning, exit 0. The rebuild's
user-unit step now works (`restarting the following user units:
nixos-activation.service`), which is the direct proof of the causal chain: kill
the trigger and all three symptoms clear together.

**So: hull's config is clean. The trigger is a second WSL distro running.**

**Operating rule until Phase 7:** terminate the other distro before opening NixOS.
```powershell
wsl --terminate fedoraremix
wsl --terminate NixOS     # so NixOS cold-boots with Fedora already gone
```
Terminating NixOS too matters - resuming a NixOS session that *started* while
Fedora was up keeps the failed unit. If you see the banner, this is why; it is not
a regression in hull. The problem disappears permanently when Fedora retires.

**Constraint this places on the environment modules:** `systemd.user` services
work on a clean start, but will fail on any boot where Fedora was running. Until
Phase 7, do not make `shell` / `editor` / `tools` *depend* on Home Manager user
services. File-based config (zsh, neovim, git, starship) is unaffected either
way - prefer it. **As built, Phase 2 obeys this**: every module is file/package
config, no user services.

Note home-manager as a NixOS module does install a `home-manager-nixos.service`
(a system unit, not a user unit), so activation does not depend on the broken
user manager.

## Session log - 2026-07-27 (Phase 1 close-out)

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
- `docs/how-it-works.md` - flakes vs modules, evaluation vs activation.

**Verified:** zero-error baseline with both distros terminated, twice. Also a
reproducibility check - the same `nix.conf` store hash
(`n6qz6cc0ihib9y16g8vcl5c1kzazcsnj`) and the same system toplevel (`vhza8gd7…`)
were computed on Fedora and produced on NixOS independently.

**Two corrections worth remembering:**
- `nix flake check` passed a config that could not build (`claude-code`'s unfree
  licence). Only `nix build --dry-run` forces package derivations. Use it as the
  gate - this is why that rule is above.
- The first garbage collection freed 3.9 GB against a 1–2 GB estimate. Do not
  treat store growth estimates as reliable; measure.

## Session log - 2026-07-27 (Phase 2 build)

The first session run entirely from inside NixOS. Nothing was switched into; the
captain runs that.

**Decided:**
- **Drop the word "panel"** - see the vocabulary section at the top.
- **Split the planned `env` module into `shell` / `editor` / `tools`.** `env` was
  a grab-bag holding shell, editor, multiplexer, CLI tools and a language
  runtime, and it collided with the system map, where "the ship's body" is hull.
- **Phase 2 is porting, not interface design.** With one host consuming the
  modules there is nothing to design - options exist so a *second* consumer can
  differ, and `native` does not exist. Deferred to Phase 6. `ROADMAP.md` carries
  the full reasoning.
- **Out-of-store symlinks for nvim and herdr config**, store-managed for
  everything else. Reasoning in `ARCHITECTURE.md`.
- **No agent memory files on this project** - everything durable goes in these
  documents.

**Built:** `flake.nix` (home-manager input + NixOS module), `hosts/wsl.nix`
(zsh login shell, home-manager block), `modules/paths.nix`, `modules/shell`,
`modules/editor` (+ nvim lua copied from the quarry), `modules/tools`
(+ herdr config.toml).

**Dropped deliberately on port** - do not "restore" these, they were Fedora
artifacts:
- `glibcLocales` override + `LOCALE_ARCHIVE` + `LANG`. Verified on NixOS:
  `LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive` and
  `LANG=en_US.UTF-8` are already correct. v1 needed them only because Fedora is
  a foreign host.
- `home.sessionPath = [ "$HOME/.local/bin" ]`. That existed for v1's imperatively
  installed `hull` launcher; Phase 4's CLI is a Nix package.
- v1's `accountCommand` zsh function generator - that is git-identity, Phase 3.

**Verified by evaluation and by a real build (not switched):**
- `nixos-rebuild build --flake .#wsl` → `Done.`, exit 0.
- Login shell resolves to `zsh-5.9.1`.
- User packages resolve: fd, fzf, herdr 0.7.5, jq, lazygit, neovim 0.12.4,
  nodejs 22.23.1, ripgrep, starship, zsh.
- Both out-of-store links resolve into the working tree -
  `~/.config/nvim → /home/nixos/hull/modules/editor/nvim` and
  `~/.config/herdr/config.toml → /home/nixos/hull/modules/tools/herdr/config.toml`.
- `herdr` confirmed absent from 26.05, present in unstable at 0.7.5.

**Not verified - needs a human in the shell:** the prompt, autosuggestions,
keybindings, nvim actually launching and lazy.nvim fetching plugins, herdr
running. That is the first task of the next session.

**Correction worth remembering:** `nix build --dry-run` listed `nodejs-22.23.1`
under "these derivations will be built", implying a long source compile.
Substitutability checks and the real build both disproved it. The dry-run's
build/fetch split is not a reliable cost estimate.

## Session log - 2026-07-28 (Phase 2 switch, VS Code, identity)

**Switched into Phase 2.** `sudo nixos-rebuild switch --flake ~/hull#wsl`
completed `Done.` at exit 0. Two things in the output worth noting: `removing
profile version 7` (the generation cap firing unattended, first observation of it
during a real switch) and `restarting the following user units:
nixos-activation.service` - the user-unit step that normally fails, working,
because Fedora was not running.

**Verified live afterwards**, rather than by evaluation:
- Login shell is zsh; `nvim`, `herdr`, `starship`, `lazygit`, `fd`, `jq`, `node`
  all resolve from `/etc/profiles/per-user/nixos/bin/`.
- Both out-of-store symlinks resolve into the working tree. Note they are
  **two-hop** links (`~/.config/nvim` → `home-manager-files` → `hm_nvim` →
  `~/hull/modules/editor/nvim`), so a single `readlink` looks like it points into
  the store and is misleading. Use `readlink -f`.
- Generations 8, 9, 10 held.

**Added `programs.nix-ld.enable`** to fix VS Code Remote-WSL - full reasoning in
its own section above.

**Decided the identity** - `alx`, noreply emails on both accounts. Full reasoning
in its own section above. The burnish numeric id is verified against the API; the
flintec one is not.

**Reviewed the v1 registry** (`flake.nix` + `profile.nix`, pasted from the Fedora
machine). Three things must not carry over:
1. `hull.url = "path:/home/adam/burnish-studio/hull-fedora"` - an absolute path
   containing the old username, pointing at the frozen v1. This *is* "Gap C".
2. **The dependency direction is inverted.** v1 had registry depending on hull
   (registry's flake took hull as an input and called `hull.lib.mkHome`). The
   design in `ARCHITECTURE.md` has **hull taking registry as an input**, so
   registry becomes pure data. The flip is correct - hull produces
   `nixosConfigurations` and owns the hosts - and was confirmed by the captain
   2026-07-28.
3. `fullName = "alex"` with `hosts.wsl.username = "adam"` and
   `hosts.laptop.username = "alex"` - the exact naming drift `alx` resolves.

Worth keeping from it: the `accounts` structure, org/alias/key naming (matches
D1.5), and `default = true` on burnish.

**Inventoried the home directory.** Almost everything in it is imperative runtime
state written by tools, not by Nix - see "What Nix owns" above. `.copilot` is a
single lock file from a VS Code extension pushed in from the Windows side; the
captain did not ask for it and does not intend to use it. Uninstalling the
extension (or disabling it for the remote) stops it reappearing. Nothing to do on
the hull side.

**Committed and pushed, in three commits:**
- `fb22b3d` - Phase 2 live, nix-ld, identity decided. The first push was
  **rejected**; see "Two machines" above for what happened and the lesson.
- `3b6291e` - the nvim plugin lock and the Kun review findings.

**Cloned Kun's dotfiles to `~/dotfiles` and reviewed the whole repo.** Findings
recorded in their own section above. The actionable one: hull was missing
`lazy-lock.json`, now fixed.

**Adopted a house style** - there was none before. See "House style" below. The
em dash sweep it implies is agreed but **not started**; it is the next task and
is fully specified there.

**Two corrections the captain made to the agent, both worth keeping:**
- Do not use acronyms where a full word exists. Recorded under "Working with the
  captain".
- Do not describe hull's existing writing as a deliberate "house style" that
  Kun's conventions "diverge from". There was no style; the em dashes were just
  default agent output. Framing an accident as a decision led to a wrong
  recommendation ("adopt deliberately or not at all") on a question that was
  actually easy.

## Session log - 2026-07-28 (the house-style sweep)

A short session: read the project cold, then executed the em dash sweep that the
previous session had specified. Commit `2eecde4`, pushed.

**Done:** all 256 em dashes converted across the 12 files in scope. `docs/adr/*`
left alone as historical records; the 12 en dashes untouched.

**The specified pattern was incomplete, and this is the reusable lesson.** The
sweep was written as "replace `' — '` with `' - '`". That would have missed
**18 of the 256**, which are not surrounded by spaces because the dash landed at
the end or the start of a wrapped line. Worse, one was line-*initial*, where a
blind replacement produces `- ` at the start of a markdown line and silently
converts a sentence into a bullet. That paragraph (in the `user@1000` constraint
section) was re-wrapped instead. **When sweeping a character out of prose, match
the character, not a spaced instance of it, and check for line-initial hits.**

**Build gate:** `nixos-rebuild build --flake .#wsl` at exit 0, producing
`7q2ssf8v7xdr63q79wp0lhw1i2vvgvia` - **byte-identical to running generation 10**.
That is a stronger result than the gate usually gives: it proves the six `.nix`
files changed nothing evaluable, rather than merely proving they still build. A
useful trick to reuse whenever a change is meant to be inert.

Note the sweep spec said the `.nix` files were "comments only". Nearly true -
`flake.nix`'s `description` is a string, not a comment. The identical toplevel
confirms it makes no difference, since flake description is metadata that never
reaches the system closure.

**Corrected in this file:** the state block claimed everything through `3b6291e`
was on `origin/main`, which was two commits stale and was the first thing a cold
agent would read. Now `2eecde4`.

**Verified live** (not evaluated): generation 10 running with 8, 9, 10 held;
zsh the login shell; both out-of-store symlinks resolving into the working tree;
`systemctl --failed` empty; git 2.54.0, gh 2.96.0, claude-code 2.1.220.

**Found, and it sharpens an existing item:** `~/.local/share/nvim` does not exist
at all, so nvim has never been launched here. See "What is NOT done".

**Adopted:** the close-out convention at the top of this file - every session
updates HANDOVER before it ends. The captain's instruction, and the natural
consequence of this project having no agent memory files.

## Session log - 2026-07-28 (herdr keys, the `agents` module)

The captain's first real session *using* the environment rather than building it.
He is new to neovim and to multiplexers, so much of this was guided use, and the
findings came out of that use rather than out of review.

**Phase 2 is now fully verified.** `nvim` was launched for the first time on this
machine; lazy.nvim bootstrapped and installed all 9 pinned plugins, and
`lazy-lock.json` came back **unchanged** afterwards, which is the lock doing its
job. rose-pine renders correctly in truecolor - visible in the plugin manager's
purple/teal/amber. That closes the last outstanding Phase 2 claim.

**A `COLORTERM` worry was raised and then disproved.** `COLORTERM` is empty in
this shell, which usually signals no truecolor. Neovim queries the terminal
directly instead of trusting it, so rose-pine was fine. Do not re-investigate.

**herdr keybindings reverted to herdr's own defaults.** The inherited config set
12 keys; **eight of them merely restated herdr's defaults verbatim**, and three
were deliberate tmux overrides carried from Kun (`%` / `"` for splits, `&` for
close-tab). The captain has no tmux muscle memory, so the overrides bought him
nothing while costing a Shift press each. Only `copy_mode` was a real decision and
it stayed. Three keys change in use: splits are `prefix+v` / `prefix+minus`, and
close-tab is `prefix+shift+x`.

The reusable point: **restating a default is not documentation, it is a silent
pin.** If herdr changed a default, hull would hold the old value with nobody
having decided to. The file now holds decisions only, and points at `prefix+?`
and `herdr --default-config` for the rest.

**`prefix = ctrl+b` was kept, and it is not arbitrary** - it is herdr's default
*and* tmux's. The usual "improvement" to `ctrl+a` collides with beginning-of-line
in zsh, which is used constantly. `h/j/k/l` was likewise already the default.

**Built `modules/agents`** - the first slice of Phase 5. It holds `claude-code`
(moved out of `hosts/wsl.nix`, and from a system to a user package) plus the
Claude Code `settings.json` and status line, both linked out-of-store so they are
edited live. Switched, verified, running on generation 11.

**Three real defects found in the ported v1 status line**, none of which would
have shown up by reading it:

1. **It could never have run on NixOS.** It parsed the session JSON with python3,
   commented as "stable at /usr/bin/python3", because "jq is not guaranteed on
   this machine". On NixOS both halves are false in the *opposite* direction:
   there is no `/usr/bin/python3` and no `python3` on PATH at all, while `jq` is
   declared in `modules/tools`. Rewritten in jq. The lesson is that a portability
   assumption written down on one host becomes a landmine on the next.
2. **The gh identity lookup could never succeed.** It ran `timeout 1 gh api user`.
   Measured here across four runs: 1.05-1.09s, consistently. So the timeout killed
   it every single time and the segment vanished silently once the 30s cache
   expired - which is exactly why it looked fine in early testing. Replaced by
   reading `user:` from gh's own `hosts.yml`, which is the same fact held locally
   and is what `gh auth switch` rewrites. **No network, no timeout, no cache, no
   stale window** - and the whole status line went from >1s to 0.052s.
3. **It hardcoded identity.** A case statement mapped `burnish-studio` -> `burnish`
   and `flintec-studio` -> `flintec`. That is identity data in an
   identity-agnostic public repo (ADR 0002). Caught by the captain, not the agent.
   It now prints whatever account gh reports, so the file is correct on any
   machine for any account. Short display labels, if ever wanted, belong in the
   registry - it is private and already holds the aliases (D1.5).

**Dropped from the v1 `settings.json` on port:** a `WebFetch` allowance for a
client's domain and an enabled `vercel` plugin. Both are project-scoped, and the
client domain would have published a client relationship in a public repo. The
likely origin is an "always allow" answer during a session on that project being
written to the *user-level* settings file. Only the opinions came across: model,
effort level, tui, theme, and the status line command.

**The out-of-store pattern proved itself in anger.** The timeout bug was fixed by
editing the script and re-running it - live, no rebuild - because
`~/.claude/statusline.sh` points into the repo. That is the exact benefit the
architecture claims for the exception, demonstrated rather than asserted.

**Two corrections the captain made, both worth keeping:**
- Do not attribute a beginner's difficulty to a config decision. The claim that
  the `Esc`-saves binding had "caused two problems in twenty minutes" was wrong;
  neither incident was caused by it. He was learning a new tool.
- The `JetBrainsMono Nerd Font Mono` reference in the v1 status line was called a
  stray that "matches nothing else in the project". It was not - it described the
  **Windows Terminal** font, while `wezterm.lua` says `Hack Nerd Font` because
  that file came from Kun and describes the laptop. Two terminals, two fonts, and
  the comment was accurate about its own context.

**A keybinding rethink is wanted, deferred deliberately.** `Ctrl-r` for redo is
awkward; the usual fix is binding `U` (whose default "undo line" is near-useless).
The `Esc`-to-save binding is a fair candidate to revisit at the same time. Both
live in `modules/editor/nvim/lua/keys.lua`, which is out-of-store, so it is an
edit with no rebuild.

**herdr's agent integrations, and where they belong.** herdr can learn an agent's
real state (idle / working / needs attention) instead of guessing from process
detection, if the agent reports it. `herdr integration install claude` writes a
hook to `~/.claude/hooks/herdr-agent-state.sh` and registers it as a
`SessionStart` hook in `~/.claude/settings.json` - which is now hull's file, so
the change appeared as a git diff immediately. That is the out-of-store design
working exactly as intended.

**The integration installed and did nothing.** Its fourth guard is
`command -v python3 || exit 0`, and this machine had no python3. It would have
run on every session start and silently reported nothing, with herdr quietly
falling back to the weaker mechanism. `python3` is now declared in
`modules/agents` for this reason. **Second time in one day** a ported tool
assumed python3 exists here - the status line was the first. Treat "does this
shell out to python3?" as a standing question for anything arriving on NixOS.

**The hook script itself is deliberately NOT vendored into hull.** Its own header
says herdr overwrites it on reinstall, it carries
`HERDR_INTEGRATION_VERSION=7`, and herdr's settings panel reports when a copy is
outdated. Vendoring would pin version 7 forever and mean hand-maintaining another
project's generated code. This is *not* the `lazy-lock.json` case: that pins
third-party plugins at versions we chose, which is reproducibility we own.

**What hull should own instead** - the agent packages, their dependencies, and
eventually the *trigger*. A Home Manager activation script running `herdr
integration install <agent>` is declarative trigger over imperative content, and
is the "lifecycle tool" idea from `CONTEXT.md`. Not built yet, deliberately: with
one machine and a command already run by hand, there is no blocker to justify it.
It earns its keep at Phase 6's second host, or when a third agent arrives.

**A Gap-C-shaped problem in what herdr wrote.** The registered hook command is
`bash '/home/nixos/.claude/hooks/herdr-agent-state.sh' session` - an absolute path
containing the username, committed to a portable repo. **It breaks on the `nixos`
to `alx` rename.** Do not hand-fix it; herdr overwrites the file on reinstall.
Re-run `herdr integration install claude` after the rename and it regenerates
correctly. The eventual activation script removes the problem entirely.
Note also that herdr **reformats** settings.json when it touches it (keys
alphabetised, trailing newline dropped), so expect noisy diffs there.

**`pi` added as the second agent harness** (`pi-coding-agent`, MIT, so no unfree
allowance needed). It is used for non-Anthropic models. Taken from `unstable`
even though 26.05 *has* it - a weaker justification than herdr's absence, and
stated in the module: 26.05 carries 0.75.4 against unstable's 0.81.1, and an
agent CLI that cannot self-update goes stale against the model APIs it talks to,
which is the failure claude-code already hit. **The policy this settles: agent
CLIs track upstream, everything else takes the pin.** `pi`'s own herdr
integration is not installed yet - it lands at
`~/.pi/agent/extensions/herdr-agent-state.ts`.

**Corrected in this file's working assumptions:** an agent claimed this session
was running inside a herdr pane, inferred from the live snapshot showing two
Claude panes. The process tree showed otherwise - it ran under a plain zsh from
Windows Terminal, and the herdr panes were separate sessions. The practical
consequence was a wrong warning that `herdr server stop` would kill the
conversation. Check `/proc` rather than infer from a snapshot.

**A trap that cost a round trip: herdr does not re-read its config on its own.**
An edit looked broken for half an hour because the running server had loaded the
file at startup and never reloaded. `herdr server reload-config` logs an
`api.request` line, so the log is the way to tell whether a reload actually
happened - absence of that line is proof it did not. Now documented in the module
comment. Generalise it: **out-of-store means no *rebuild*, not no *reload*.**
zsh needs a rebuild plus a new shell, nvim needs reopening, herdr needs an
explicit reload.

**One `AGENTS.md`, linked to both agents.** Kun's one-source-many-targets
pattern, which completes Phase 5's wiring. The paths are **not** a shared
convention and were verified rather than assumed: Claude Code reads
`~/.claude/CLAUDE.md`, pi reads `~/.pi/agent/AGENTS.md` (pi's own README: it
loads `AGENTS.md` or `CLAUDE.md` from the global path, parent directories and
the current directory, concatenating every match). Kun links three targets
because he runs three tools; hull links two because it declares two. Codex and
opencode are one line each if ever added and were deliberately not added
speculatively.

The house style **moved** into that file rather than being copied, so there is
one source and no drift. Only the history of its adoption stayed in this
document.

**`AGENTS.md` at the repo root, and why it matters more than it looks.** The
captain's instruction, 2026-07-28: keeping hull clear and quick to orient in is
**every** agent's ongoing responsibility, not a task. The concrete defect it
fixes is that this session's agent knew the build gate, the division of labour
and the hard boundaries only because it read a 1200-line document first, and
nothing enforced that. The root `AGENTS.md` is 73 lines and is loaded
automatically by both agent tools, so the load-bearing rules arrive whether or
not anyone reads the state. `CLAUDE.md` is a **committed git symlink** to it
(mode 120000), so one file serves both tools' conventions.

Recorded as step 7 of the close-out checklist above, with the emphasis on
*correcting and shortening* over appending.

**Answered "what happens on a fresh machine", which was written down nowhere.**
Its own section above. The load-bearing finding: Home Manager creates the
intermediate directories for `home.file`, so `~/.pi/agent/AGENTS.md` links
correctly even though pi has never run - and those directories stay **real**,
with only the leaf file symlinked, so each tool still writes its own state
beside them. That is the same property that makes the herdr `config.toml`
file-level link work, confirmed a second time.

**Honest note on document size.** This file went from 1074 to 1311 lines in one
session, which is the opposite of the direction just committed to. The content is
real, but a deliberate compression pass is queued in "Start here" rather than
attempted in a hurry at the end of a long session.

**Verified live, not by evaluation:** generation 11 with 9, 10, 11 held; the
activation cap dropped 8 during the switch; the four out-of-store links existing
at that point resolve
into the working tree; `claude` present in the user profile and absent from
`/run/current-system/sw/bin`; the status line renders in 0.052s with the identity
segment correct; `herdr config check` clean. The built closure
(`avcvrgwz7m6…`) was byte-identical to the one the pre-switch gate produced.

**Re-measured 2026-07-28 (guest side, end of this session):** guest 7.4 GB used,
store 6.3 GB, `~/.vscode-server-insiders` 678 MB - all within noise of the
previous reading the same day. Versions: git 2.54.0, gh 2.96.0, claude-code
2.1.220, neovim 0.12.4, herdr 0.7.5.

## Session log - 2026-07-28 (preparing the account rename)

A short session with one job: get the `nixos` → `alx` rename ready to run. The
hull-side change is small; almost all the value was in testing the recorded
procedure, **three steps of which were wrong**.

**What was wrong is corrected in the rename section above, not restated here** -
one source. In summary: the old account does not linger and needs no `userdel`;
the `mv` must precede the switch or `createHome` nests the home directory; the
prescribed `uid = 1000` was a redundant restatement of a NixOS-WSL default. A
fourth problem was not in the document at all - **`nixos-rebuild switch --flake`
cannot run from a root login**, because nix reads flakes through libgit2, which
rejects a repository owned by another uid.

The generalisable lesson, and the reason all four were missed: **every one of
them was invisible to reading and obvious to testing.** `dry-activate` reported
the user removal, a five-second `sudo env -u SUDO_UID` reproduced the libgit2
refusal, and `createHome` was one `nix eval`. A procedure written from
documentation and never rehearsed is a draft, and this one had been sitting in
the file described as recorded fact since 2026-07-27.

**The hostname was decided rather than inherited**, as the document asked. `wsl`,
declared in `hosts/wsl.nix`. Ruled out: `hull` and `nixos` both fail a
hostname's only job, since the Phase 6 machine will also be running hull, on
NixOS. Host type is the axis that separates them, and it already names the flake
attribute and the registry's `hosts.wsl` key, so the machine's name now matches
its configuration's name. ADR 0002.A lists hostname as identity, but 0002.C makes
hull explicitly host-type-aware - `wsl` is host type; `alx-laptop` would be the
breach that clause guards against.

**One deliberate ADR breach, flagged rather than slipped in.** ADR 0002.A says
zero identity in hull - "no name / account / key / hostname". `username = "alx"`
in `hosts/wsl.nix` violates that. It was taken knowingly, for a reason worth
recording: the alternative was to leave the rename to Phase 3, which would then
perform a fiddly OS-level rename *and* the registry wiring in a single switch -
two risky things at once. Renaming now keeps them separate, and lets Phase 3 be a
pure refactor that changes the *source* of the name rather than the name itself.
The binding sits once in a `let` and is used at all three sites, so Phase 3
removes the breach by swapping one line.

**The "do it while the home directory is nearly empty" argument turns out to be
weak**, and the file had leaned on it. The mechanism is a `mv`, which is O(1)
whatever the directory holds. What actually grows with time is the number of
files with `/home/nixos` baked in - and that was measured rather than guessed:
only Claude's own `history.jsonl` (transient), the herdr hook path registered in
`settings.json` (regenerated by reinstalling the integration), and 11 files in
`~/.vscode-server-insiders` (logs and caches; delete the directory). `~/.gitconfig`
and `gh/hosts.yml` hold **no** home paths and survive untouched. So the real
argument for doing it now is the Phase 3 sequencing above, not the calendar.

**Verified by evaluation, not assumed:** `alx` gets uid 1000, home `/home/alx`,
`isNormalUser`, groups `wheel`; the generated `/etc/wsl.conf` carries
`hostname=wsl` and `default=alx`; `users.users.nixos` is no longer a declared
attribute; and `hull.repoPath` derives to `/home/alx/hull`, so all six
out-of-store symlinks re-point with no path edits - `modules/paths.nix` earning
its keep. The build gate is green and produced
`nixos-system-wsl-26.05.20260722.b3fe958`, with `home-manager-alx.service` in the
closure.

**Re-measured 2026-07-28 at close:** guest 8.2 GB used, store 7.0 GB - up 0.2 GB
from the start of the session, which is the new system closure and nothing else.
Nothing was switched, so still generation 13.

**This file grew again, by ~200 lines, and that is the second session running.**
Most of it is the rehearsed procedure, which is worth its space until the rename
is done and can then be cut to a few lines. The session log above was deliberately
kept short and points at that section rather than repeating it. Compression is
task 2 in "Start here" - after the rename, not before, because the procedure is
what the next session needs most.

## Session log - 2026-07-28 (the rename ran)

Short session, cut off by the clock. The captain ran the rename from a Windows
root shell exactly as the rehearsed procedure said, and **it worked first time
with no surprises** - which is the point of the rehearsal session before it, and
the only real evidence that testing a procedure beats reading one.

**Verified on the machine, not inferred from the switch output:** `id` gives
`uid=1000(alx) gid=100(users) groups=100(users),1(wheel)`; hostname `wsl`;
`/home/alx` is the only home directory and `/home/nixos` is gone; login shell is
the wrapped zsh; all six out-of-store symlinks resolve into `/home/alx/hull`.
Generation 14 is both current and booted, with 12, 13, 14 held - the switch
dropped 11, as the cap intends.

**The strongest check was the cheapest.** Re-running `nixos-rebuild build --flake
.#wsl` produced `yrxd0p72dx5apj40jfwyx4p0xis3dj7w-nixos-system-wsl-…`, byte-for-byte
the path in `/run/current-system` and `/run/booted-system`. That is one command
proving the working tree and the running machine are the same artefact, and it
beats any number of individual spot-checks. Worth doing at the top of any session
that arrives after someone else switched.

**The herdr hook is broken and the document had the reason slightly wrong.**
HANDOVER said the registered path "will break on the rename", which is right, but
it read as though reinstalling were purely mechanical. It is not: the file is a
symlink into the working tree, so `herdr integration install claude` writes
`/home/alx` **into a public repo**. That is a second ADR 0002 breach and a
decision, not a step - it is now written up as task 1 with three options rather
than as a command to run. Left undone deliberately; the captain picks.

**Also corrected:** "Current system state" still claimed the user was `nixos` and
the running generation was **10**. It had been stale for two switches. Fixed, and
noted here rather than silently, per the close-out rule - the lesson is that a
section titled "current" ages worse than the session logs around it, because
nothing about it looks out of date.

**Compressed:** the rename procedure went from ~112 lines of rehearsal script to
~70 of history, keeping the one caveat that outlives it (`nixos-rebuild --flake`
cannot read the flake from a root login, because libgit2 rejects a
foreign-uid repo). Net -47 lines on the file, the first session it has shrunk.
Task 3 in "Start here" - the real compression pass over the session logs - is
still open.

**Re-measured 2026-07-28 at close:** guest 8.2 GB used, store 7.0 GB,
`~/.vscode-server-insiders` 678 MB. Unchanged across the session; nothing was
built that was not already in the store.

## Session log - 2026-08-04 (agent tooling PATH)

Not a hull session by intent. The captain was bringing **firstmate** (the third
repo, `~/firstmate`) up to operational readiness and hit hull as the blocker, so
the hull change is small and the reasoning is most of what is worth keeping.

**What changed:** one line, `home.sessionPath = [ "$HOME/.local/bin" ]`, in
`modules/tools/default.nix`, with the reasoning in a comment there and a pointer
added to that file's "NOT here, deliberately" header.

**Why it had to be hull rather than imperative, which is the counter-intuitive
part.** The tools themselves are deliberately outside hull - treehouse,
no-mistakes and five `*-axi` npm packages, none in nixpkgs, installed into
`~/.local/bin` with npm's prefix pointed there via `~/.npmrc`. The captain's
instinct was that this add-on layer should sit on top of hull and simply not be
clobbered by reruns, and that instinct is right: **checked against the Home
Manager manifest, HM owns `~/.local/state` but not `~/.local/bin`**, so rebuilds
never touch the tools. But PATH is generated *wholly* by HM, so a PATH set
anywhere else is the one thing a rerun does discard. Declaring the directory is
what makes the imperative layer above it durable. The inversion is worth
remembering: hull owning the *pointer* is what keeps the *contents* free.

**Verified, not asserted:** `nixos-rebuild build --flake .#wsl` succeeds and the
generated `hm-session-vars.sh` contains exactly
`export PATH="$HOME/.local/bin${PATH:+:}$PATH"` - `$HOME` unexpanded at build
time, so no account name enters the repo. Build is
`bfc54klc9fgb6bg5ihb26fl9p93wyxxf-…`; `/run/current-system` is still
`yrxd0p72dx5apj40jfwyx4p0xis3dj7w-…`. **Not switched** - captain's step.

**An unrelated write landed in the tree and should be reviewed before commit.**
Running `gh-axi setup hooks` (and the same for `chrome-devtools-axi` and
`lavish-axi`) appends `SessionStart` entries to `~/.claude/settings.json`, which
is an out-of-store symlink, so three hook blocks appeared in
`modules/agents/claude/settings.json` unprompted. That is the documented and
intended consequence of the out-of-store link making drift visible, not a
malfunction - but it is the exact hazard that file's comment warns about, so it
was read before being left in place. **Checked: identity-free, no domains, no
secrets, safe for a public repo.** Note the hooks invoke bare command names, so
they silently do nothing until the `sessionPath` change is switched.

**Corrections made to this file:** "What is NOT done" still listed the account
rename as pending on the machine; it has been done since 2026-07-28 and the
top-of-file block already said so. Struck. The state block's "working tree and
running machine are the same artefact" claim was true at the rename close and is
now false, so it has been re-scoped to that date rather than left standing. Disk
figures were not re-measured and are now labelled a week stale rather than quietly
carried forward.

**Left for the captain, unresolved deliberately:** task 1's herdr hook decision.
It stopped being cosmetic this session - firstmate now supervises on the herdr
backend and consumes exactly the agent state that dead registration feeds - so
its cost is recorded in task 1, but the three-way choice is still his.

## What is NOT done

- ~~The interactive environment has not been lived in.~~ **Done 2026-07-28.**
  nvim launched for the first time, lazy.nvim installed all 9 pinned plugins,
  `lazy-lock.json` unchanged afterwards, rose-pine rendering correctly. herdr
  keybindings still want a hands-on pass, but the module is proven.
- ~~The Linux account is still `nixos` on the machine.~~ **Done 2026-07-28** -
  the rename was switched and verified (`uid=1000(alx)`, `/home/nixos` gone).
  This entry still read as pending on 2026-08-04 and was corrected then; the
  top-of-file state block had recorded it as done since the rename session.
- **The agent tools in `~/.local/bin` are imperative and unreproducible** (new
  2026-08-04). treehouse, no-mistakes and the five `*-axi` packages have no
  nixpkgs derivations, so they are installed by npm and by upstream install
  scripts. hull declares only the PATH entry (`modules/tools`); it does not
  install, pin, update or remove any of them, and a rebuild will not restore them
  on a fresh machine. Same category as SSH keys, and stated as such in the
  module. A version-drift or supply-chain question about those tools is not a
  question hull can answer.
- ~~The two GitHub email-privacy settings are not enabled.~~ **Closed
  2026-07-28** - the noreply addresses in use came from those settings pages, so
  privacy is on. *Block command-line pushes that expose my email* is a separate
  tick that cannot be checked through the API; worth confirming by eye once.
- **hull holds one hardcoded username, knowingly** - `username = "alx"` in
  `hosts/wsl.nix`, which breaches ADR 0002.A. Taken deliberately so the rename
  could happen in isolation rather than inside Phase 3's first switch. It is
  bound once in a `let`, so Phase 3 removes it by swapping a single line for
  `registry.hosts.wsl.username`. Do not let it settle in.
- **Git identity is repo-local to `~/hull` only** - every other repo on this
  machine, including `hull-fedora`, still cannot commit.
- **Module options are undesigned**, deliberately - Phase 6, when `native` shows
  what needs to vary.
- **nvim plugins are pinned but not Nix-managed** (corrected 2026-07-28).
  `lua/plugin.lua` bootstraps lazy.nvim, which git-clones plugins into
  `~/.local/share/nvim` at runtime, so Nix does not manage them and first launch
  needs network. But `nvim/lazy-lock.json` now pins all 9 to exact commits, so
  the *set* is reproducible even though the *mechanism* is not. `:Lazy update`
  rewrites the lock as a reviewable git diff.
  Earlier versions of this file said plugins were "not reproducible… true in v1
  too, not a regression". That was wrong in an important way: **Kun ships a
  `lazy-lock.json` and hull had dropped it.** The plugin specs were verified
  byte-identical to his, so the lock was the only missing piece. Do not remove it.
- **`git-identity` (Phase 3) does not exist.**
- **`agents` (Phase 5): the wiring is done, one thing is owed.** It holds
  `claude-code`, `pi`, `python3`, the Claude Code settings and status line, and
  one `AGENTS.md` linked to both agents' global instructions paths. Still owed:
  triggering `herdr integration install` declaratively from a Home Manager
  activation script, so a fresh machine gets the agent-state integrations without
  anyone remembering. See the Phase 5 entry in `ROADMAP.md` for the constraint
  that makes a naive version fail.
- **Registry ↔ flake wiring** is unsolved (registry has no GitHub remote yet;
  must avoid v1's hardcoded-path "Gap C"). Note `modules/paths.nix` now solves
  the *same class* of problem for out-of-store links - reuse the pattern.
- **The `hull` CLI** does not exist yet (Phase 4).
- **The `alx` user** is not configured - current default user is `nixos`. Real
  user comes from the registry (Phase 3), though the rename can happen sooner.
- **`hosts/native.nix`** does not exist - Phase 6.
- A NixOS minimal ISO is on a USB stick ready for the laptop (Phase 6 prep).
- **nvim keybindings want a deliberate pass.** `Ctrl-r` for redo is awkward -
  bind `U` instead. The `Esc`-saves binding should be reconsidered at the same
  time. `modules/editor/nvim/lua/keys.lua`, out-of-store, so no rebuild.
- **The status line icons depend on a Windows-side font.** JetBrainsMono Nerd
  Font is installed and working, but it is manual and undeclared - it belongs on
  the Windows checklist alongside WezTerm. `CLAUDE_STATUSLINE_ICONS=0` falls back
  to text labels if a machine lacks it.
- **herdr agent integrations are installed by hand, not by hull.** Both `claude`
  (v7) and `pi` (v6) are installed and report `current`. hull declares the
  packages and their dependencies but does not yet trigger `herdr integration
  install`. Deliberate - see the session log. The trigger belongs in a Home
  Manager activation script and earns its keep at the second host. Note it must
  initialise each agent first: `herdr integration install pi` fails outright
  until the agent has been run once and created its config directory.
- **pi has no API keys yet.** `~/.pi/agent/auth.json` exists and is empty (mode
  600). Per-machine secret state, never in Nix or git - same rule as the SSH
  keys. pi cannot reach deepseek or kimi until keys are added there.
- **The claude integration's registered hook path still hardcodes
  `/home/nixos/`**, so the `SessionStart` hook now fires at a path that does not
  exist. Confirmed broken 2026-07-28, after the rename. This is task 1 in "Start
  here" and carries a decision about writing `/home/alx` into a public repo -
  read it there rather than just running the reinstall.
- **`~/.vscode-server-insiders` holds 11 files referencing `/home/nixos`** - logs,
  caches and two copilot helpers, still present after the rename. Delete the
  directory and let VS Code re-inject it; it is imperative state hull already
  disclaims. Task 2 in "Start here".
- **Stale agent state under the old path**: `~/.claude/projects/-home-nixos-hull/`
  holds this tool's own session transcripts, and `~/.claude/history.jsonl` and the
  herdr logs carry `/home/nixos` strings. Cosmetic, and it is agent state rather
  than hull's, but it is why grepping `$HOME` for `/home/nixos` still returns
  hits after tasks 1 and 2 are done.
- **~5 GB is trapped in the WSL virtual disk** - one manual Windows-side
  compaction recovers it.
- **Fedora is still installed and holds 78.47 GB.** Retirement deferred by the
  captain 2026-07-27 pending a migration pass. Do not delete it unprompted.

## Immediate next step

The ordered task list is at the top of this file under "Start here". This section
holds only the detail that does not fit there.

**On Phase 3 - `git-identity`.** This is the real deep-module work, and it
   is gated on one thing outside the code: **the registry has no GitHub remote.**
   Pushing it to a private repo is the prerequisite. Read the Phase 3
   carry-forward constraints in `ROADMAP.md` before designing anything - D1.3
   (port 443 unconditionally) and D1.5 (org-based naming) are non-obvious and
   were paid for once already.

**On mining `hull-fedora`:** a note in the previous handover said `home/` holds
only `AGENTS.md` and that everything is inline in a monolithic `home.nix`. That
is half right and was corrected 2026-07-27. `home/.config/` does hold tidy,
portable `nvim/`, `wezterm/` and `herdr/` configs - those copied across as files.
What *is* inline in `home.nix` is the git-identity logic (accounts → gitconfig
includes, URL rewrites, ssh blocks, the per-account shell functions), roughly
lines 9–104 and 165–196. That extraction is Phase 3's work - budget for it there,
not before.

## House style

**The rules now live in [`modules/agents/AGENTS.md`](modules/agents/AGENTS.md)**,
which is linked to `~/.claude/CLAUDE.md` and `~/.pi/agent/AGENTS.md`, so every
agent tool loads them automatically. They were parked in this file until
something actually read them; as of 2026-07-28 something does, so they moved
rather than being duplicated here.

Only the history stays here. hull had **no** house style before 2026-07-28 -
documents were written in whatever the agent produced by default, which is why
they were full of em dashes. That was never a decision anyone made, and framing
it as one led to a wrong recommendation once already. The captain adopted Kun's
base conventions as a working default, explicitly **"not gospel today forever"**.

Two rules in that file are hull's own rather than Kun's: writing acronyms out in
full, and "verify, do not assert". Both were earned here.

### The em dash sweep is done (2026-07-28, commit `2eecde4`)

All 256 instances across the 12 files converted; `docs/adr/*.md` left alone as
historical records, and the 12 en dashes (`–`) untouched. What the sweep taught
about doing this kind of pass is in the session log for that date.

**Two** em dashes legitimately survive outside `docs/adr/`, each quoting the
character as its own subject: the rule itself in `modules/agents/AGENTS.md`, and
one quotation of the sweep pattern in this file. It was three until the house
style moved out of here and the duplicate went with it. Verified by grep
2026-07-28. A future automated pass will hit them; that is expected, and they
should be put back.

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
- **Write acronyms out in full** where a full version exists - "garbage
  collection", not "GC"; "Home Manager", not "HM". He should not have to guess
  at an abbreviation to read an explanation.
- **Follow the house style above.** It is a working default, not doctrine, and
  he expects it to evolve.
- **He is learning NixOS as this is built.** Explain mechanisms, not just
  conclusions - what "unfree" means, what a rebuild does and does not touch, why
  a symlink makes a file appear in two places. He asks good questions when given
  something to grip.
- **Verify, do not assert.** Several claims in this file were wrong until
  checked: the SIGCHLD root cause, the "five settings" host description, plugins
  being irreproducible. Check the machine, then write it down.
- **Don't add co-author lines to git commits** on this repo.

## Hard boundaries (do not cross)

- **hull never touches Windows.** No `/mnt` reads/writes, no `cmd.exe` /
  `powershell.exe`. The Windows-side setup (WezTerm, fonts) is a manual
  checklist. (The neovim `clip.exe` clipboard bridge is the one agreed
  exception, and lives in ported content.)
- **Company network drives** (`/mnt/d`, `/mnt/e`) must never be touched.

## Tooling note

**Corrected 2026-07-27.** A previous version of this file said project skills
(`/grill-with-docs` etc.) live in `hull-fedora/.claude/skills/`. They do not -
that clone has no `.claude/` directory; only `home/.claude/settings.json` and
`home/.claude/statusline-command.sh` are tracked. The skills were installed on
the Fedora machine via `npx` (Matt Pocock's set - grill-with-docs and the ADR
format) and were never committed anywhere. They are reinstallable from source, so
nothing is lost; do not go looking for them in the repo.

This repo's remote is `github.com/burnish-studio/hull` (public); `hull-fedora` is
at `github.com/burnish-studio/hull-fedora` (private, hence `gh auth`).
