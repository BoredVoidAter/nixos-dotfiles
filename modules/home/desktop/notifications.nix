{ pkgs, ... }:

{
  services.mako = {
    enable = true;
    font = "JetBrainsMono Nerd Font 11";
    backgroundColor = "#11111bee";
    textColor = "#cdd6f4";
    borderColor = "#89b4fa";
    borderRadius = 10;
    borderSize = 2;
    padding = "12";
    defaultTimeout = 5000;
    layer = "overlay";
  };

  home.packages = with pkgs; [
    libnotify
  ];
}
