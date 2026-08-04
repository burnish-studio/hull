# Command-line tools that are identical on every host, plus herdr's config.
#
# NOT here, deliberately:
#   git, gh   - in hosts/<host>.nix as system packages. `sudo nixos-rebuild`
#               runs as root and needs git to read a flake from a git repo; a
#               user-profile git is invisible to root and the rebuild breaks.
#   fzf       - installed by `programs.fzf.enable` in modules/shell.
#   the agent tools in ~/.local/bin - not packaged by nixpkgs at all. hull
#               declares the PATH entry for them at the bottom of this file but
#               owns nothing inside it; see the comment there.
{ config, pkgs, unstable, ... }:
{
  imports = [ ../paths.nix ];

  home.packages = [
    pkgs.ripgrep # fast search
    pkgs.fd # fast find
    pkgs.jq # json on the command line
    pkgs.lazygit

    # Node.js LTS + npm/npx. Nix is the version manager: pin here, not nvm.
    pkgs.nodejs_22

    # terminal / agent multiplexer. Verified absent from 26.05 and present in
    # unstable (0.7.5), so it must come from the unstable input - it is the
    # second such package after claude-code, not the only one.
    unstable.herdr
  ];

  # Link the config FILE, not the directory. herdr writes runtime state -
  # sockets, logs, session.json - into its config dir; a directory symlink puts
  # that state in the repo, and a socket in the repo makes the path uncopyable
  # by Nix ("unsupported type"), breaking every build. A file-level link keeps
  # ~/.config/herdr a real directory herdr can scribble in.
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.hull.repoPath}/modules/tools/herdr/config.toml";

  # --- PATH for tools nixpkgs does not carry ----------------------------------
  # Several agent tools ship only as npm packages or upstream install scripts and
  # have no derivation to put in home.packages above: treehouse, no-mistakes, and
  # the *-axi family (gh-axi, lavish-axi, chrome-devtools-axi, tasks-axi,
  # quota-axi). They are installed imperatively into ~/.local/bin - the
  # conventional user prefix, which both upstream installers select by name, and
  # which npm targets via `npm config set prefix ~/.local` (recorded in ~/.npmrc).
  #
  # This one line is the ONLY part of that arrangement hull owns, and it has to
  # live here rather than be set imperatively: PATH is generated wholly by Home
  # Manager, so a PATH edit made outside the config is precisely what the next
  # rebuild discards. Declaring the directory is what lets the imperative layer
  # above it survive reruns.
  #
  # hull does not manage the directory or anything in it. Home Manager owns
  # ~/.local/state but NOT ~/.local/bin (checked against the manifest, 2026-08-04),
  # so rebuilds neither install, update, nor remove those tools. They stay
  # imperative per-machine state, the same category as SSH keys - deliberate,
  # because they self-update and declaring them would claim a reproducibility
  # this repo would not actually deliver.
  #
  # `$HOME` rather than an interpolation of config.home.homeDirectory:
  # sessionPath entries are written into a shell script and expanded at runtime,
  # so this form keeps the account name out of a public repo (ADR 0002).
  home.sessionPath = [ "$HOME/.local/bin" ];
}
