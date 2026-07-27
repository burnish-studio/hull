# Host type: NixOS-WSL. No GUI — the Windows-side wrapper (WezTerm, fonts)
# stays manual and out-of-tree; hull never touches Windows.
{ config, lib, pkgs, ... }:
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

  # --- Disk hygiene (ADR 0006) -------------------------------------------------
  # WSL gives the guest a ~1 TB sparse filesystem on a 474 GB physical disk, so it
  # never sees disk pressure and Nix's pressure-driven GC (min-free/max-free) can
  # never fire. And a WSL virtual disk grows but never shrinks, so the *peak* store
  # size is what permanently costs Windows disk. Hygiene must therefore be tied to
  # the event that grows the store — the rebuild — not to a schedule or threshold.
  # Do NOT copy this to hosts/native.nix: on a real disk, min-free/max-free is the
  # better mechanism and this is unnecessary.

  # Hardlink identical files as they enter the store. Continuous, no trigger.
  nix.settings.auto-optimise-store = true;

  # Cap generations on every activation. This runs on any `nixos-rebuild switch`
  # however it was invoked, so the ceiling cannot be bypassed. Deleting generation
  # symlinks is instant. Capping is the precondition for garbage collection being
  # effective at all — GC can only reclaim what no surviving generation pins.
  # Keep 3: current, previous, and one spare last-known-good. Losing older ones
  # costs time, not recoverability — any past system rebuilds from any git commit.
  # `|| true` so a failure here can never fail a rebuild.
  system.activationScripts.hullCapGenerations = ''
    ${config.nix.package}/bin/nix-env \
      --profile /nix/var/nix/profiles/system \
      --delete-generations +3 || true
  '';

  system.stateVersion = "26.05";
}
