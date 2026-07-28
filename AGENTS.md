# Working on hull

Project instructions for any agent working in this repo. Loaded automatically by
Claude Code and pi, so you have these rules without reading anything else.

This file is deliberately short. It is the rules you need before you touch
anything; **`HANDOVER.md` is the state** and is where you go next.

hull is a NixOS flake producing one reproducible developer environment for two
host types (`wsl`, `native`). It holds no personal identity - that lives in a
separate private registry repo.

## Before you start

1. **`git pull`.** A second machine can still push here and has done so
   mid-session.
2. Read **`HANDOVER.md`** - current state, what is done, what is not, and the
   session logs. Everything durable about this project lives in documents, not
   in agent memory.

## The rules that have cost time when broken

- **Gate every change with `nixos-rebuild build --flake .#wsl`.** Non-destructive:
  it builds the system and activates nothing. `nix flake check` is NOT sufficient
  - it proves the config is well-formed but does not force package derivations,
  so it misses unfree-licence and missing-package errors. A broken `claude-code`
  was pushed exactly this way.
- **Flakes only see git-tracked files.** A new module is invisible until
  `git add`ed. Committing is not required; staging is. The error says "file does
  not exist", which is misleading.
- **The captain runs `nixos-rebuild switch`.** You design, edit, build and
  verify; he runs the destructive and experiential steps. Do not switch for him.
- **Verify, do not assert.** Several claims in these documents were wrong until
  someone checked. Check the machine, then write down what you found.
- **Home Manager aborts activation rather than overwrite a file it did not
  create.** Before adding a `home.file`, check whether the target already exists.
  If it does, that is a step for the captain to clear first.

## Where a change takes effect

Two categories, and knowing which decides how you change something:

| | Store-managed | Out-of-store linked |
| --- | --- | --- |
| Examples | zsh, aliases, starship, packages | nvim lua, herdr toml, agent config |
| To apply | edit the `.nix`, rebuild, switch | edit the file |

Out-of-store means no *rebuild*. It does not mean no *reload*: nvim needs
reopening, and herdr needs `herdr server reload-config` or `prefix+shift+r`.

## Hard boundaries

- **hull never touches Windows.** No `/mnt` reads or writes, no `cmd.exe` or
  `powershell.exe`. Windows-side setup (WezTerm, the Nerd Font) is a manual
  checklist. The neovim `clip.exe` clipboard bridge is the one agreed exception.
- **Company network drives (`/mnt/d`, `/mnt/e`) must never be touched.**
- **No secrets in Nix or git, ever.** The Nix store is world-readable. SSH keys
  and API tokens are per-machine state, created imperatively, never declared.
- **No identity in hull.** No account names, no emails, no usernames hardcoded.
  hull is identity-agnostic (ADR 0002) and public. Identity comes from the
  registry.

## Before you finish

**Every session updates `HANDOVER.md` before it ends.** This is not housekeeping,
it is the mechanism the project runs on: there are no agent memory files here, so
a session that ends without writing back has lost what it learned. The close-out
checklist is at the top of that file.

**Keeping this repo clear and quick to onboard is part of every session, not a
separate task.** If you had to dig for something a newcomer will also need, that
is a documentation defect - fix it where it lives. Prefer correcting and
shortening over appending; a document nobody can finish reading protects nobody.
