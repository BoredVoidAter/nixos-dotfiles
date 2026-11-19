{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      n = "nvim";
      python = "python3";
      unity = "nvidia-offload unityhub";
      sops-edit = "nix shell nixpkgs#sops -c sops ~/nixos-dotfiles/secrets/secrets.yaml";
      
      # Unified system update commands
      update = "bash ~/nixos-dotfiles/config/vicinae/scripts/system-update.sh";
      update-local = "cd ~/nixos-dotfiles && nix flake update && sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-btw && sudo nix-collect-garbage -d && sudo nix-store --optimise";
    };
  };
}
