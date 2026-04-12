{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 10;
          y = 10;
        };
        opacity = 1.0;
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
        size = 11.0;
      };

      colors = {
        primary = {
          background = "#0D0D0D"; # Your deep black
          foreground = "#D9BC9A"; # Your Tan text
        };
        
        cursor = {
          text = "#0D0D0D";
          cursor = "#D9BC9A";
        };

        normal = {
          black   = "#1D1D1D";
          red     = "#590202"; # Your custom dark red
          green   = "#9ece6a";
          yellow  = "#e0af68";
          blue    = "#7aa2f7";
          magenta = "#ad8ee6";
          cyan    = "#0db9d7";
          white   = "#a9b1d6";
        };

        bright = {
          black   = "#444b6a";
          red     = "#ff7a93";
          green   = "#b9f27c";
          yellow  = "#ff9e64";
          blue    = "#7da6ff";
          magenta = "#bb9af7";
          cyan    = "#0db9d7";
          white   = "#c0caf5";
        };
      };
    };
  };
}
