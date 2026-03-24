{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      n = "nvim";
      # Since we installed Unity via Nix, we can usually just run unityhub
      unity = "nvidia-offload unityhub";         
      aw = "firefox http://localhost:5600";
      ym = "yt";
      sops-edit = "nix shell nixpkgs#sops -c sops ~/nixos-dotfiles/secrets/secrets.yaml";
      
      # Downloads YouTube video/playlist as CD-ready WAV files
      yt-cd = "yt-dlp -f 'ba' -x --audio-format wav";
    };
  };
}
