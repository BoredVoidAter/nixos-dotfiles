{ pkgs, spicetify-nix, ... }:

let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{

  programs.imv = {
    enable = true;
    settings = {
      options = {

        background = "0d0e11";
      };
    };
  };


  programs.zathura = {
    enable = true;
    options = {

      default-bg = "#0d0e11";
      default-fg = "#e6e6ea";
      statusbar-bg = "#131418";
      statusbar-fg = "#8c8f9a";
      inputbar-bg = "#18191e";
      inputbar-fg = "#e6e6ea";
    };
  };

  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
    ];
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  home.packages = with pkgs; [
    xarchiver # GUI archive manager (works perfectly with Thunar)
    playerctl
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {

      "text/html" = [ "librewolf.desktop" ];
      "x-scheme-handler/http" = [ "librewolf.desktop" ];
      "x-scheme-handler/https" = [ "librewolf.desktop" ];
      "x-scheme-handler/about" = [ "librewolf.desktop" ];
      "x-scheme-handler/unknown" = [ "librewolf.desktop" ];

      "image/jpeg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
      "image/tiff" = [ "imv.desktop" ];
      "image/bmp" = [ "imv.desktop" ];
      "image/svg+xml" = [ "imv.desktop" ];


      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ]; # mkv
      "video/webm" = [ "mpv.desktop" ];
      "video/x-msvideo" = [ "mpv.desktop" ]; # avi
      "video/quicktime" = [ "mpv.desktop" ]; # mov


      "audio/mpeg" = [ "mpv.desktop" ]; # mp3
      "audio/ogg" = [ "mpv.desktop" ];
      "audio/x-wav" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];


      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];


      "application/zip" = [ "xarchiver.desktop" ];
      "application/x-tar" = [ "xarchiver.desktop" ];
      "application/x-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-bzip-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-xz-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-7z-compressed" = [ "xarchiver.desktop" ];
      "application/vnd.rar" = [ "xarchiver.desktop" ];
    };
  };
}
