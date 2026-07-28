# neovim, and the lua config it reads.
#
# The config is linked OUT of the Nix store (see modules/paths.nix): editing
# modules/editor/nvim/*.lua takes effect on the next nvim start, with no rebuild.
# That is deliberate — nvim config is iterated on constantly, and nvim already
# manages its own plugins imperatively (lua/plugin.lua bootstraps lazy.nvim,
# which git-clones plugins into ~/.local/share/nvim at runtime). Plugins are
# therefore NOT reproducible from this repo; only the config is.
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
