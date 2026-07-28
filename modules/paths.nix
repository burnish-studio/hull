# Where hull is checked out on this machine.
#
# Needed by any module that uses `mkOutOfStoreSymlink` - that mechanism links a
# config file in the live repo rather than a read-only copy in the Nix store, so
# it needs a real filesystem path that Nix cannot supply. Modules that need it
# import THIS file rather than each declaring the option, so the declaration
# exists exactly once and every module stays independently importable. (Nix
# dedupes imports by path, so importing it from two modules is fine.)
#
# v1 hardcoded `~/.dotfiles` here, which is the "Gap C" failure - the repo could
# only live in one place. An option with a derived default keeps the zero-config
# case working while leaving the path overridable per host.
{ config, lib, ... }:
{
  options.hull.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/hull";
    description = ''
      Absolute path to the hull checkout, used to build out-of-store symlinks
      for configs that are edited live (nvim, herdr). Override if hull is
      cloned somewhere other than ~/hull.
    '';
  };
}
