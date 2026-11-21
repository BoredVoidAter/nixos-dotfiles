{ pkgs, lib, ... }:

let
  iconDir = ../../../config/icons;
  entries = if builtins.pathExists iconDir then builtins.readDir iconDir else { };

  svgNames = map (lib.removeSuffix ".svg") (
    builtins.filter (name: entries.${name} == "regular" && lib.hasSuffix ".svg" name) (builtins.attrNames entries)
  );

  pngNames = map (lib.removeSuffix ".png") (
    builtins.filter (name: entries.${name} == "regular" && lib.hasSuffix ".png" name) (builtins.attrNames entries)
  );

  svgDataFiles = lib.listToAttrs (lib.concatMap (name:
    let
      src = iconDir + "/${name}.svg";
      png = pkgs.runCommand "${name}-icon.png" { } ''
        ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${src} $out
      '';
    in
    [
      {
        name = "icons/hicolor/scalable/apps/${name}.svg";
        value.source = src;
      }
      {
        name = "icons/hicolor/512x512/apps/${name}.png";
        value.source = png;
      }
    ]
  ) svgNames);

  pngDataFiles = lib.listToAttrs (map (name: {
    name = "icons/hicolor/512x512/apps/${name}.png";
    value.source = iconDir + "/${name}.png";
  }) (lib.filter (n: !(builtins.elem n svgNames)) pngNames));
in
{
  home.packages = with pkgs; [
    hicolor-icon-theme
  ];

  xdg.dataFile = svgDataFiles // pngDataFiles;
}
