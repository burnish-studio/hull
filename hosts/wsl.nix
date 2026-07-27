# Host type: NixOS-WSL. No GUI — the Windows-side wrapper (WezTerm, fonts)
# stays manual and out-of-tree; hull never touches Windows.
{ pkgs, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos"; # replaced with the registry-injected user in Phase 3

  # `nixos-rebuild --flake` passes these itself, so rebuilds work without them —
  # but bare `nix` (flake update/check, and the Phase 4 `hull` CLI per ADR 0004)
  # does not. Declare them so the machine does not depend on installer state.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # git is needed to clone hull locally; rebuilding from a local path avoids the
  # GitHub fetcher serving a stale commit (see HANDOVER, rebuild workflow).
  environment.systemPackages = [ pkgs.git ];

  system.stateVersion = "26.05";
}
