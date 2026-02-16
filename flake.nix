{
  description = "NixOS from Scratch";

  inputs = {
    # Unstable (Default)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Stable (For broken packages like Aseprite)
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playit-nixos-module.url = "github:pedorich-n/playit-nixos-module";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, playit-nixos-module, sops-nix, nix-flatpak, ... }: 
  let
    system = "x86_64-linux";
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos-btw = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager

	nix-flatpak.nixosModules.nix-flatpak


        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            
            # Pass 'pkgs-stable' so home.nix can use it
            extraSpecialArgs = { inherit pkgs-stable sops-nix; };
            
            users.boredvoidater = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
        playit-nixos-module.nixosModules.default
      ];
    };
  };
}
