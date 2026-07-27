{
  description = "hull — reproducible NixOS dev environment (wsl + native)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Track the release branch matching nixpkgs, not `main` — `main` drifts into
    # the next release's development while nixpkgs stays on 26.05. The ref is the
    # update policy; flake.lock supplies the reproducibility.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, ... }: {
    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.default
        ./hosts/wsl.nix
      ];
    };
  };
}
