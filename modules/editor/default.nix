# neovim, and the lua config it reads.
#
# The config is linked OUT of the Nix store (see modules/paths.nix): editing
# modules/editor/nvim/*.lua takes effect on the next nvim start, with no rebuild.
# That is deliberate - nvim config is iterated on constantly, and nvim already
# manages its own plugins imperatively (lua/plugin.lua bootstraps lazy.nvim,
# which git-clones plugins into ~/.local/share/nvim at runtime).
#
# Plugins are therefore not managed by Nix, but they ARE pinned:
# nvim/lazy-lock.json records an exact commit per plugin, and lazy.nvim installs
# those revisions rather than whatever HEAD happens to be. First launch still
# needs network. `:Lazy update` rewrites the lock - and because this directory is
# the working tree, that rewrite lands as a reviewable git diff instead of
# vanishing into ~/.local/share. Updating plugins is a commit, not a side effect.
#
# lazy.nvim finds the lock via its default path, stdpath("config")/lazy-lock.json,
# which resolves through the symlink into this repo. Do not set `lockfile` in
# lua/plugin.lua - the default is already correct here.
#
# The cost of the out-of-store link: `nixos-rebuild --rollback` does not revert
# nvim config, and the link dangles if hull is not at hull.repoPath.
{ config, pkgs, ... }:
{
  imports = [ ../paths.nix ];

  home.packages = [ pkgs.neovim ];

  home.sessionVariables.EDITOR = "nvim";

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.hull.repoPath}/modules/editor/nvim";
}
