{ config, pkgs, lib, ... }:

let
  
  # 2. Existing Config
  recolorConfig = {
    config = {
      colors = {
        "CANVAS" = [ "Background" "#1a1b26" "#1a1b26" "--canvas" ];
        "CANVAS_OVERLAY" = [ "Background (menu)" "#16161e" "#16161e" "--canvas-overlay" ];
        "CANVAS_ELEVATED" = [ "Review" "#24283b" "#24283b" "--canvas-elevated" ];
        "FG" = [ "Text" "#a9b1d6" "#a9b1d6" "--fg" ];
        "FG_SUBTLE" = [ "Text (subtle)" "#787c99" "#787c99" "--fg-subtle" ];
        "FG_LINK" = [ "Text (link)" "#7aa2f7" "#7aa2f7" "--fg-link" ];
        "BUTTON_BG" = [ "Button bg" "#24283b" "#24283b" "--button-bg" ];
        "BUTTON_PRIMARY_BG" = [ "Button Primary" "#7aa2f7" "#7aa2f7" "--button-primary-bg" ];
        "ACCENT_CARD" = [ "Card mode" "#1a1b26" "#1a1b26" "--accent-card" ];
        "ACCENT_NOTE" = [ "Note mode" "#9ece6a" "#9ece6a" "--accent-note" ];
        "ACCENT_DANGER" = [ "Danger" "#f7768e" "#f7768e" "--accent-danger" ];
        "BORDER" = [ "Border" "#414868" "#414868" "--border" ];
        "BORDER_FOCUS" = [ "Border Focus" "#7aa2f7" "#7aa2f7" "--border-focus" ];
        "SCROLLBAR_BG" = [ "Scrollbar" "#16161e" "#16161e" "--scrollbar-bg" ];
        "SCROLLBAR_BG_HOVER" = [ "Scrollbar Hover" "#24283b" "#24283b" "--scrollbar-bg-hover" ];
        "BUTTON_HOVER" = [ "Button Hover" "#2f334d" "#2f334d" "--button-hover" ];
        "HIGHLIGHT_BG" = [ "Highlight Bg" "#2f334d" "#2f334d" "--highlight-bg" ];
        "HIGHLIGHT_FG" = [ "Highlight Fg" "#c0caf5" "#c0caf5" "--highlight-fg" ];
      };
      version = { major = 3; minor = 1; };
    };
  };

  anki-recolor = pkgs.ankiAddons.recolor.withConfig recolorConfig;
  anki-connect = pkgs.ankiAddons.anki-connect;
  review-heatmap = pkgs.ankiAddons.review-heatmap;

in
{
  home.packages = [
    (pkgs.anki.withAddons [
      anki-recolor
      anki-connect
      review-heatmap
    ])
    
    pkgs.antimicrox

  ];

  home.sessionVariables = {
    ANKI_WAYLAND = "1"; # Try toggling this if issues persist
    ANKI_NOHIGHDPI = "0";
    QT_STYLE_OVERRIDE = lib.mkForce "fusion"; 
    
    # Potential fix for slow startup / GPU issues
    QTWEBENGINE_CHROMIUM_FLAGS = "--disable-gpu";
  };
}
