{ config, pkgs, lib, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "BoredVoidAter";
      user.email = "boredvoideater@proton.me";
      credential.helper = "/run/current-system/sw/bin/gh auth git-credential";
      filter.lfs = {
        clean = "/run/current-system/sw/bin/git-lfs clean -- %f";
        process = "/run/current-system/sw/bin/git-lfs filter-process";
        required = true;
        smudge = "/run/current-system/sw/bin/git-lfs smudge -- %f";
      };
    };
  };

  # Ensure git-lfs and gh are available
  home.packages = with pkgs; [
    git-lfs
    gh
  ];
}