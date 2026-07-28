# Host type: NixOS-WSL. No GUI - the Windows-side wrapper (WezTerm, fonts)
# stays manual and out-of-tree; hull never touches Windows.
{ config, lib, pkgs, unstable, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos"; # replaced with the registry-injected user in Phase 3

  # `nixos-rebuild --flake` passes these itself, so rebuilds work without them -
  # but bare `nix` (flake update/check, and the Phase 4 `hull` CLI per ADR 0004)
  # does not. Declare them so the machine does not depend on installer state.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # git: clone hull locally so rebuilds run from a path, not the GitHub fetcher
  # (which can serve a stale commit - see HANDOVER, rebuild workflow).
  # gh: authentication for the private `hull-fedora` quarry and for pushing.
  # Already a declared runtime dep of `hull account add` (ADR 0004), so this is
  # pulling a known-needed tool forward, not a new dependency.
  #
  # These are SYSTEM packages, not user packages, on purpose: `sudo nixos-rebuild`
  # runs as root and needs `git` to read a flake from a git repo. A git installed
  # only into the user's Home Manager profile is invisible to root.
  #
  # `claude-code` used to sit here too, marked temporary. It moved to
  # modules/agents 2026-07-28 and became a user package in the process - the
  # root-needs-it reason above never applied to it.
  environment.systemPackages = [ pkgs.git pkgs.gh ];

  # --- Foreign binaries ---------------------------------------------------------
  # VS Code Remote-WSL injects a server into ~/.vscode-server*/ from the Windows
  # side: a generic-linux prebuilt `node` that asks for the interpreter
  # /lib64/ld-linux-x86-64.so.2. NixOS is not FHS, so that path holds `stub-ld` -
  # a decoy whose only job is to print "cannot run dynamically linked executables"
  # and point at https://nix.dev/permalink/stub-ld. nix-ld replaces the decoy with
  # a real loader and supplies a base library set (libstdc++, zlib, openssl, curl,
  # systemd - see nixos/modules/programs/nix-ld.nix), which is what node needs.
  #
  # Chosen over nix-community/nixos-vscode-server, which patchelfs the server via
  # a systemd USER service - precisely what HANDOVER forbids depending on while
  # the user@1000 bug lives. nix-ld is a system-level setting, so it is immune.
  #
  # This does not breach "hull never touches Windows": VS Code runs over there and
  # connects inward; hull only permits the injected binary to execute. The server
  # itself is downloaded imperatively and is NOT reproducible from this repo -
  # same category as lazy.nvim's plugins (see modules/editor), already accepted.
  #
  # Lives at the host layer, not in a module: `native` does not exist yet, so
  # there is no second consumer to design a seam for (ADR 0003). Promote it in
  # Phase 6 if the native host wants it too.
  programs.nix-ld.enable = true;

  # --- User environment --------------------------------------------------------
  # zsh must be enabled at the NixOS level and named as the account's shell:
  # Home Manager's `programs.zsh` configures zsh but cannot change the login
  # shell, which is a property of the user account in /etc/passwd.
  programs.zsh.enable = true;
  users.users.nixos.shell = pkgs.zsh;

  # Home Manager runs as a NixOS module, so `nixos-rebuild switch` activates the
  # user environment in the same atomic switch as the system. The modules below
  # are host-agnostic; host-specific variation (GUI, wezterm, fonts) stays here.
  home-manager = {
    useGlobalPkgs = true; # HM builds against the system nixpkgs, not its own
    useUserPackages = true; # user packages into /etc/profiles, not ~/.nix-profile
    extraSpecialArgs = { inherit unstable; };
    users.nixos = {
      imports = [
        ../modules/shell
        ../modules/editor
        ../modules/tools
        ../modules/agents
      ];
      home.stateVersion = "26.05";
    };
  };

  # --- Disk hygiene (ADR 0006) -------------------------------------------------
  # WSL gives the guest a ~1 TB sparse filesystem on a 474 GB physical disk, so it
  # never sees disk pressure and Nix's pressure-driven GC (min-free/max-free) can
  # never fire. And a WSL virtual disk grows but never shrinks, so the *peak* store
  # size is what permanently costs Windows disk. Hygiene must therefore be tied to
  # the event that grows the store - the rebuild - not to a schedule or threshold.
  # Do NOT copy this to hosts/native.nix: on a real disk, min-free/max-free is the
  # better mechanism and this is unnecessary.

  # Hardlink identical files as they enter the store. Continuous, no trigger.
  nix.settings.auto-optimise-store = true;

  # Cap generations on every activation. This runs on any `nixos-rebuild switch`
  # however it was invoked, so the ceiling cannot be bypassed. Deleting generation
  # symlinks is instant. Capping is the precondition for garbage collection being
  # effective at all - GC can only reclaim what no surviving generation pins.
  # Keep 3: current, previous, and one spare last-known-good. Losing older ones
  # costs time, not recoverability - any past system rebuilds from any git commit.
  # `|| true` so a failure here can never fail a rebuild.
  system.activationScripts.hullCapGenerations = ''
    ${config.nix.package}/bin/nix-env \
      --profile /nix/var/nix/profiles/system \
      --delete-generations +3 || true
  '';

  system.stateVersion = "26.05";
}
