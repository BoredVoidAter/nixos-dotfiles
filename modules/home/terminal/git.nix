{ config, pkgs, lib, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "BoredVoidAter";
      user.email = "boredvoideater@proton.me";
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
      filter.lfs = {
        clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
        process = "${pkgs.git-lfs}/bin/git-lfs filter-process";
        required = true;
        smudge = "${pkgs.git-lfs}/bin/git-lfs smudge -- %f";
      };
    };
  };

  # Ensure git-lfs and gh are available
  home.packages = with pkgs; [
    git-lfs
    gh
  ];
}
