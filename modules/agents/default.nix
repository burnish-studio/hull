# Agent tooling: the Claude Code package and its configuration.
#
# `claude-code` lived in hosts/wsl.nix until this module existed - the host file
# said so and called it temporary. It is not host-specific: any host type wants
# the same agent tooling, so it belongs in a concern module (ADR 0003).
#
# It moves from a SYSTEM package to a USER package in the same step. The host
# file keeps git and gh as system packages for a stated reason - `sudo
# nixos-rebuild` runs as root and needs git to read a flake from a git repo -
# and that reason does not apply here. Nothing runs claude-code as root.
{ config, pkgs, unstable, ... }:
{
  imports = [ ../paths.nix ];

  # From `unstable`, not the 26.05 pin: a Nix-installed binary cannot self-update,
  # and Claude Code ships often enough that the release branch goes stale within
  # weeks (26.05 carried 2.1.187 against unstable's 2.1.220 - old enough to not
  # list the current models). One of exactly two packages taken from unstable;
  # herdr in modules/tools is the other. Its unfree licence is allowed by name in
  # flake.nix, not by a blanket allowUnfree.
  # python3: a hard dependency of herdr's agent-state integration hooks, not a
  # general-purpose addition. `herdr integration install claude` writes a hook to
  # ~/.claude/hooks/herdr-agent-state.sh whose fourth guard is
  # `command -v python3 || exit 0` - so without python3 the hook installs
  # successfully, runs on every session start, and silently does nothing. herdr
  # then falls back to guessing agent state from process detection, which is the
  # weaker mechanism this integration exists to replace.
  #
  # Found the hard way 2026-07-28, and it is the second tool that day to assume
  # python3 exists on a machine that has none - the ported status line was the
  # first. Treat "does this shell out to python3?" as a standing question for
  # anything ported onto NixOS.
  # pi: the second agent harness, used for non-Anthropic models (deepseek, kimi).
  # MIT licensed, so unlike claude-code it needs no unfree allowance.
  #
  # Taken from `unstable` despite being PRESENT in 26.05, which is a weaker
  # justification than herdr's (herdr is simply absent from the release branch).
  # The reason is the same one claude-code already carries: an agent CLI that
  # cannot self-update goes stale against the model APIs it talks to, and 26.05
  # already lags - 0.75.4 there against 0.81.1 on unstable, six minor versions.
  # claude-code hit exactly this (2.1.187 was too old to list current models).
  # The policy this settles: agent CLIs track upstream, everything else takes the
  # pin. Flip `unstable.` to `pkgs.` here if that trade ever stops being worth it.
  home.packages = [
    unstable.claude-code
    unstable.pi-coding-agent
    pkgs.python3
  ];

  # Both files are linked OUT OF STORE, straight into the working tree, for two
  # reasons. First, a status line is iterated on constantly, and an out-of-store
  # link means editing the file is the whole workflow - no rebuild. Second,
  # Claude Code WRITES to settings.json (a theme change via /config, an
  # "always allow" permission rule), and a store path is read-only, so a
  # store-managed settings.json would make the application fail to save.
  #
  # The consequence is deliberate and worth stating: anything Claude Code writes
  # to its settings lands in this repo's working tree and shows up in `git
  # status`. That is the point - it makes configuration drift visible instead of
  # silent. It is also a hazard, because hull is PUBLIC: an "always allow" rule
  # naming a client domain would be written here. v1's settings.json had exactly
  # that (a WebFetch allowance for a client's domain, dropped on port). Check
  # `git diff` on this file before committing, and put project-scoped permissions
  # in that project's own .claude/settings.json rather than here.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.hull.repoPath}/modules/agents/claude/settings.json";

  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.hull.repoPath}/modules/agents/claude/statusline.sh";

  # --- Global agent instructions: one source, one link per agent ---------------
  # Kun's one-source-many-targets pattern. A single AGENTS.md is linked to each
  # agent tool's global instructions path, so every harness reads the same policy
  # and there is exactly one file to edit.
  #
  # The paths are NOT a shared convention - each tool has its own, verified
  # rather than assumed:
  #   Claude Code  ~/.claude/CLAUDE.md
  #   pi           ~/.pi/agent/AGENTS.md   (pi's README: "Pi loads AGENTS.md (or
  #                CLAUDE.md) at startup from ~/.pi/agent/AGENTS.md (global),
  #                parent directories, and the current directory")
  #
  # Kun links three targets because he runs three tools; hull links two because
  # it declares two. Adding `.codex/AGENTS.md` or `.config/opencode/AGENTS.md` is
  # one line each if those agents are ever declared here - do not add them
  # speculatively.
  #
  # Out-of-store like everything else in this module: agent policy is edited far
  # more often than it is rebuilt.
  #
  # Note both tools ALSO read a project-level AGENTS.md / CLAUDE.md and
  # concatenate it with this one, so project-specific rules have a proper home
  # and must not be added here.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.hull.repoPath}/modules/agents/AGENTS.md";

  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.hull.repoPath}/modules/agents/AGENTS.md";
}
