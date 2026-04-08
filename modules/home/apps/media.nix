{ pkgs, ... }:

{

  programs.imv = {
    enable = true;
    settings = {
      options = {

        background = "1a1b26";
      };
    };
  };


  programs.zathura = {
    enable = true;
    options = {

      default-bg = "#1a1b26";
      default-fg = "#a9b1d6";
      statusbar-bg = "#24283b";
      statusbar-fg = "#a9b1d6";
      inputbar-bg = "#24283b";
      inputbar-fg = "#a9b1d6";
    };
  };

  home.packages = with pkgs; [
    xarchiver # GUI archive manager (works perfectly with Thunar)
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {

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
