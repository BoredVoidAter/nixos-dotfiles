{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    
    # You can use standard Home Manager options instead of 'settings':
    userName = "BoredVoidAter";             
    userEmail = "boredvoideater@proton.me"; # Fixed the missing 'e'
    
    extraConfig = {
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    };
  };
}
