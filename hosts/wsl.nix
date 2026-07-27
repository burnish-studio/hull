# Host type: NixOS-WSL. No GUI — the Windows-side wrapper (WezTerm, fonts)
# stays manual and out-of-tree; hull never touches Windows.
{ lib, pkgs, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos"; # replaced with the registry-injected user in Phase 3

  # `nixos-rebuild --flake` passes these itself, so rebuilds work without them —
  # but bare `nix` (flake update/check, and the Phase 4 `hull` CLI per ADR 0004)
  # does not. Declare them so the machine does not depend on installer state.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # git: clone hull locally so rebuilds run from a path, not the GitHub fetcher
  # (which can serve a stale commit — see HANDOVER, rebuild workflow).
  # claude-code: hull is developed on the machine it configures. Temporary home —
  # this moves into the `agents` panel in Phase 5. Note the Nix-installed binary
  # cannot self-update; it is pinned to whatever nixos-26.05 carries.
  environment.systemPackages = with pkgs; [ git claude-code ];

  # claude-code is unfree. Allow it by name rather than setting allowUnfree
  # globally, so every unfree package stays an explicit, visible decision.
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

  system.stateVersion = "26.05";
}
