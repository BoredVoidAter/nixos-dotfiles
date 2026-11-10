{
  description = "NixOS from Scratch";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    vicinae.url = "github:vicinaehq/vicinae";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, nix-flatpak, vicinae, spicetify-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {


        nixos-btw = nixpkgs.lib.nixosSystem {
          inherit system;


          modules = [
            ./configuration.nix
            ./modules/nixos/security.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nix-flatpak.nixosModules.nix-flatpak

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit pkgs sops-nix vicinae spicetify-nix; };
                users.boredvoidater = import ./home.nix;
                backupFileExtension = "backup";
              };
            }
          ];
        };
      };
    };
}