{
  description = "hull — reproducible NixOS dev environment (wsl + native)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, ... }: {
    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.default
        {
          wsl.enable = true;
          wsl.defaultUser = "nixos"; # replaced with registry-injected user in Phase 3
          system.stateVersion = "26.05";
        }
      ];
    };
  };
}
