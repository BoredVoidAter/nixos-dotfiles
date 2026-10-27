{ pkgs, lib, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "pangolinfoapi";
    repo = "amazon-niche-finder";
    rev = "cf6417b76d6c45c833a05ad47c3d337fcce40971";
    sha256 = "sha256-af+wKWzTtNzWI2TAorpdmFrJd3qrqk3QOsvfHegcOX8=";
  };

  # Create a wrapper script that uses the local copy
  wrapper = pkgs.writeTextFile {
    name = "amazon-niche-finder";
    text = ''
      #!${pkgs.python311}/bin/python3
      import sys
      import os
      # Resolve the real path (follow symlinks)
      real_path = os.path.realpath(__file__)
      script = os.path.join(os.path.dirname(real_path), "niche_finder.py")
      os.execv("${pkgs.python311}/bin/python3", ["python3", script] + sys.argv[1:])
    '';
  };

  # Create a package with both the script, example file, and wrapper
  amazon-niche-finder = pkgs.stdenv.mkDerivation {
    pname = "amazon-niche-finder";
    version = "unstable-2024-12-15";

    unpackPhase = ''
      mkdir -p $out
      cp -r ${src}/niche_finder.py $out/
      cp -r ${src}/niches.example.json $out/
      cp -r ${wrapper} $out/amazon-niche-finder
    '';

    # Patch the script:
    # 1. Fix cmd_init bug (accept args parameter)
    # 2. Use SCRIPT_DIR for read-only files (example), CWD for writable files
    patchPhase = ''
      sed -i 's/def cmd_init() -> None:/def cmd_init(args) -> None:/' $out/niche_finder.py
      # Replace ROOT-based paths with SCRIPT_DIR (for example) and CWD (for outputs)
      sed -i 's/ROOT = Path(__file__).resolve().parent/SCRIPT_DIR = Path(__file__).resolve().parent\nCWD = Path.cwd()/' $out/niche_finder.py
      sed -i 's/CONFIG_FILE = ROOT \/ "niches.json"/CONFIG_FILE = CWD \/ "niches.json"/' $out/niche_finder.py
      sed -i 's/EXAMPLE_FILE = ROOT \/ "niches.example.json"/EXAMPLE_FILE = SCRIPT_DIR \/ "niches.example.json"/' $out/niche_finder.py
      sed -i 's/DB_FILE = ROOT \/ "data" \/ "niches.db"/DB_FILE = CWD \/ "data" \/ "niches.db"/' $out/niche_finder.py
      sed -i 's/CSV_FILE = ROOT \/ "data" \/ "opportunities.csv"/CSV_FILE = CWD \/ "data" \/ "opportunities.csv"/' $out/niche_finder.py
      sed -i 's/REPORTS_DIR = ROOT \/ "reports"/REPORTS_DIR = CWD \/ "reports"/' $out/niche_finder.py
      # Fix the log message that references ROOT
      sed -i 's/DB_FILE.relative_to(ROOT)/DB_FILE.relative_to(CWD)/' $out/niche_finder.py
    '';

    installPhase = ''
      mkdir -p $out/bin
      chmod +x $out/niche_finder.py
      chmod +x $out/amazon-niche-finder
      ln -sf ../amazon-niche-finder $out/bin/amazon-niche-finder
    '';

    meta = with lib; {
      description = "Free & open-source Amazon niche research tool";
      homepage = "https://github.com/pangolinfoapi/amazon-niche-finder";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };
in
{
  home.packages = [ amazon-niche-finder ];
}