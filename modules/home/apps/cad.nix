{ pkgs, ... }:

let
  # Fetch the library from GitHub. 
  # Note: You will need to replace the sha256 placeholder below.
  seeed-library = pkgs.fetchFromGitHub {
    owner = "Seeed-Studio";
    repo = "OPL_Kicad_Library";
    rev = "master"; # You can pin this to a specific commit hash if you want stability
    sha256 = "sha256-p3Ay0Q6GIIwnFWGBXV3fZvgQ5iavaj27OIaijMZN//M="; # Placeholder
  };
in
{
  home.packages = with pkgs; [
    kicad
  ];

  # Symlink the library from the Nix Store to your home directory
  # Resulting Path: ~/.local/share/kicad/libraries/Seeed_OPL
  xdg.dataFile."kicad/libraries/Seeed_OPL".source = seeed-library;
}
