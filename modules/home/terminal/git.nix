{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    # userName = "Boredvoidater";             
    # userEmail = "boredvoidater@proton.me";    
    
    # extraConfig = {
    #   credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    # };
    
    settings = {
        user = {
            name = "Boredvoidater";
            email = "boredvoidater@proton.me";
        };
        credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    };
  };
}
