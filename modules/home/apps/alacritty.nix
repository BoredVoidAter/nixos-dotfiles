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
          background = "#0d0e11";
          foreground = "#e6e6ea";
        };
        
        cursor = {
          text = "#0d0e11";
          cursor = "#e6e6ea";
        };

        selection = {
          text = "#e6e6ea";
          background = "#27282f";
        };

        normal = {
          black   = "#18191e";
          red     = "#e05555";
          green   = "#3bb36a";
          yellow  = "#d4a34b";
          blue    = "#3a86ff";
          magenta = "#a855f7";
          cyan    = "#2ec4b6";
          white   = "#e6e6ea";
        };

        bright = {
          black   = "#5a5c66";
          red     = "#ea6969";
          green   = "#4cd47d";
          yellow  = "#e5b75f";
          blue    = "#5b9bff";
          magenta = "#bc7cf8";
          cyan    = "#4de0d3";
          white   = "#f4f4f6";
        };
      };
    };
  };
}
