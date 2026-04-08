{
  description = "NixOS from Scratch";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";


    neohabit-src = {
      url = "github:Vsein/Neohabit";
      flake = false;
    };


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

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, playit-nixos-module, sops-nix, nix-flatpak, neohabit-src, ... }:
    let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {



        nixos-btw = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit neohabit-src; };

          modules = [
            ./configuration.nix
            ./modules/nixos/neohabit.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nix-flatpak.nixosModules.nix-flatpak

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit pkgs-stable sops-nix neohabit-src; };
                users.boredvoidater = import ./home.nix;
                backupFileExtension = "backup";
              };
            }
            playit-nixos-module.nixosModules.default
          ];
        };




        nixos-aspire = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit neohabit-src; };

          modules = [
            ./aspire-configuration.nix



            ./modules/nixos/neohabit.nix

            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nix-flatpak.nixosModules.nix-flatpak

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit pkgs-stable sops-nix neohabit-src; };
                users.boredvoidater = import ./aspire-home.nix;
                backupFileExtension = "backup";
              };
            }
          ];
        };
      };
    };
}
