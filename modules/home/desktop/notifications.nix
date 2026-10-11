{ pkgs, ... }:

{
  services.mako = {
    enable = true;
    settings = {
      font = "JetBrainsMono Nerd Font 11";
      background-color = "#131418ee";
      text-color = "#e6e6ea";
      border-color = "#2c2d35";
      border-radius = 10;
      border-size = 1;
      padding = "12";
      default-timeout = 5000;
      layer = "overlay";
    };
  };

  home.packages = with pkgs; [
    libnotify
  ];
}
