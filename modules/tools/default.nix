# Command-line tools that are identical on every host, plus herdr's config.
#
# NOT here, deliberately:
#   git, gh   — in hosts/<host>.nix as system packages. `sudo nixos-rebuild`
#               runs as root and needs git to read a flake from a git repo; a
#               user-profile git is invisible to root and the rebuild breaks.
#   fzf       — installed by `programs.fzf.enable` in modules/shell.
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
    # unstable (0.7.5), so it must come from the unstable input — it is the
    # second such package after claude-code, not the only one.
    unstable.herdr
  ];

  # Link the config FILE, not the directory. herdr writes runtime state —
  # sockets, logs, session.json — into its config dir; a directory symlink puts
  # that state in the repo, and a socket in the repo makes the path uncopyable
  # by Nix ("unsupported type"), breaking every build. A file-level link keeps
  # ~/.config/herdr a real directory herdr can scribble in.
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.hull.repoPath}/modules/tools/herdr/config.toml";
}
