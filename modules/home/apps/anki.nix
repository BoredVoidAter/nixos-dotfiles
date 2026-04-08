{ config, pkgs, lib, ... }:

let
   # 3. AnkiConnect Config (Fix for Obsidian CORS)
  ankiConnectConfig = {
    config = {
      webCorsOriginList = [ "http://localhost" "app://obsidian.md" ];
      webBindAddress = "127.0.0.1";
      webBindPort = 8765;
    };
  };

  # Apply the config here:
  anki-connect = pkgs.ankiAddons.anki-connect.withConfig ankiConnectConfig;
  review-heatmap = pkgs.ankiAddons.review-heatmap;

in
{
  home.packages = [
    (pkgs.anki.withAddons [
      anki-connect
      review-heatmap
    ])
    
    pkgs.antimicrox

  ];
}
