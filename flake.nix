{
  description = "NixOS from Scratch";

  inputs = {
    # Switched to unstable to get Anki 'withAddons' support
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      # Updated to match unstable
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playit-nixos-module.url = "github:pedorich-n/playit-nixos-module";
  };

  outputs = { self, nixpkgs, home-manager, playit-nixos-module, ... }: {
    nixosConfigurations.nixos-btw = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.boredvoidater = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
        playit-nixos-module.nixosModules.default
      ];
    };
  };
}
