{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 12;
          y = 12;
        };
        opacity = 0.95;
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 14.0;
      };

      colors = {
        primary = {
          background = "#11111B";
          foreground = "#CDD6F4";
        };
        
        cursor = {
          text = "#11111B";
          cursor = "#F5E0DC";
        };

        normal = {
          black   = "#45475A";
          red     = "#F38BA8";
          green   = "#A6E3A1";
          yellow  = "#F9E2AF";
          blue    = "#89B4FA";
          magenta = "#F5C2E7";
          cyan    = "#94E2D5";
          white   = "#BAC2DE";
        };

        bright = {
          black   = "#585B70";
          red     = "#F38BA8";
          green   = "#A6E3A1";
          yellow  = "#F9E2AF";
          blue    = "#89B4FA";
          magenta = "#F5C2E7";
          cyan    = "#94E2D5";
          white   = "#A6ADC8";
        };
      };
    };
  };
}
