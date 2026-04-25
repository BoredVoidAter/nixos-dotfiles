# modules/home/anki.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    anki
    # CJK fonts for Chinese hanzi
    noto-fonts-cjk-sans
    source-han-serif  # Noto Serif CJK (Refold decks use serif)
  ];
}

#1771074083 Review Heatmap
#
#876946123 Pass/Fail 2
#
#738807903 More Overview Stats 2.1
#
#1240761427 Chinese Support V4
