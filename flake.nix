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

    ytm-player.url = "github:peternaame-boop/ytm-player";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, nix-flatpak, vicinae, ytm-player, ... }:
    let
      system = "x86_64-linux";

      customOverlay = final: prev: {
        nchat-patched = prev.nchat.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DHAS_TELEGRAM=OFF"
            "-DHAS_DUMMY=OFF"
            "-DHAS_TESTS=OFF"
          ];
          doCheck = false;
          postPatch = (old.postPatch or "") + ''
            cp ${./modules/home/apps/nchat/inline_media.h} src/inline_media.h
            cp ${./modules/home/apps/nchat/inline_media.cpp} src/inline_media.cpp
            cp ${./modules/home/apps/nchat/audio_info.go} lib/wmchat/go/audio_info.go
            ${prev.python3}/bin/python3 ${./modules/home/apps/nchat/patch.py}
          '';
        });

        concord-tui-fixed = prev.concord-tui.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [ prev.zstd ];
        });
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ customOverlay ];
      };
    in
    {
      packages.${system} = {
        nchat-patched = pkgs.nchat-patched;
        concord-tui-fixed = pkgs.concord-tui-fixed;
        aseprite = pkgs.aseprite;
      };

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
              nixpkgs.overlays = [ customOverlay ];
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit pkgs sops-nix vicinae ytm-player; };
                users.boredvoidater = import ./home.nix;
                backupFileExtension = "backup";
              };
            }
          ];
        };
      };
    };
}
