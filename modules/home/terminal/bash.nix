{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-btw";
      n = "nvim";
      # Since we installed Unity via Nix, we can usually just run unityhub
      unity = "nvidia-offload unityhub";         
      aw = "firefox http://localhost:5600";
      ym = "ytui_music run";
    };
  };
}
