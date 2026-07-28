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
{ config, unstable, ... }:
{
  imports = [ ../paths.nix ];

  # From `unstable`, not the 26.05 pin: a Nix-installed binary cannot self-update,
  # and Claude Code ships often enough that the release branch goes stale within
  # weeks (26.05 carried 2.1.187 against unstable's 2.1.220 - old enough to not
  # list the current models). One of exactly two packages taken from unstable;
  # herdr in modules/tools is the other. Its unfree licence is allowed by name in
  # flake.nix, not by a blanket allowUnfree.
  home.packages = [ unstable.claude-code ];

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

  # Not done here, deliberately - Phase 5 proper:
  #   * AGENTS.md and the one-source-three-targets pattern (a single file linked
  #     to .claude/CLAUDE.md, .codex/AGENTS.md and .config/opencode/AGENTS.md).
  #     That needs hull's agent instructions to be written first, which is a
  #     content decision, not a wiring one.
  #   * The house style currently recorded in HANDOVER moves into that file.
}
