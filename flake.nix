{
  description = "hull - reproducible NixOS dev environment (wsl + native)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # A second, unpinned nixpkgs for the few tools that must track upstream faster
    # than a release branch allows. Take individual packages from `unstable`
    # deliberately - never make it the default source.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Track the release branch matching nixpkgs, not `main` - `main` drifts into
    # the next release's development while nixpkgs stays on 26.05. The ref is the
    # update policy; flake.lock supplies the reproducibility.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Same release line as nixpkgs, for the same reason. Used as a NixOS module
    # (not a standalone homeManagerConfiguration as in v1), so `nixos-rebuild`
    # activates the user environment in the same atomic switch as the system.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-wsl, home-manager, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          # Available to host modules as the `unstable` argument.
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfreePredicate =
              pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
          };
        };
        modules = [
          nixos-wsl.nixosModules.default
          home-manager.nixosModules.home-manager
          ./hosts/wsl.nix
        ];
      };
    };
}
