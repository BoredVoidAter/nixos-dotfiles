{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    
    settings = {
      user = {
        name = "BoredVoidAter";             
        email = "boredvoideater@proton.me";
      };
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    };
  };
}
