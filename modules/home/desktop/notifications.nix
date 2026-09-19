{ pkgs, ... }:

{
  services.mako = {
    enable = true;
    font = "JetBrainsMono Nerd Font 11";
    backgroundColor = "#131418ee";
    textColor = "#e6e6ea";
    borderColor = "#2c2d35";
    borderRadius = 10;
    borderSize = 1;
    padding = "12";
    defaultTimeout = 5000;
    layer = "overlay";
  };

  home.packages = with pkgs; [
    libnotify
  ];
}
