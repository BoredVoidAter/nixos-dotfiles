{ pkgs, lib, ... }:

let
  # Tokyo Night Colorscheme for AnkiRecolor
  # We just pass the raw config object. We do not wrap it in "config" or metadata.
  recolorConfig = {
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
    };
    version = {
      major = 3;
      minor = 4;
    };
  };

  anki-connect = pkgs.stdenv.mkDerivation {
    pname = "anki-connect";
    version = "2024-02-27";
    src = pkgs.fetchFromGitHub {
      owner = "FooSoft";
      repo = "anki-connect";
      rev = "master";
      sha256 = "sha256-VxQ1Qu6GSdStnL/SCkzZazC3WI29hJA3Fco4ix2pOLQ=";
    };
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

  review-heatmap = pkgs.stdenv.mkDerivation {
    pname = "review-heatmap";
    version = "v1.0.0-beta.1";
    src = pkgs.fetchurl {
      url = "https://github.com/glutanimate/review-heatmap/releases/download/v1.0.0-beta.1/review-heatmap-v1.0.0-beta.1-anki21.ankiaddon";
      sha256 = "sha256-ZMK8010iITSLON3EzmuHTm8hzwQ/0X23zDJQhPZ7vBs=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

  anki-recolor = pkgs.anki-utils.buildAnkiAddon (finalAttrs: {
    pname = "anki-recolor";
    version = "3.4.1";
    
    src = pkgs.fetchFromGitHub {
      owner = "AnKing-VIP";
      repo = "AnkiRecolor";
      rev = "v${finalAttrs.version}"; 
      sha256 = "sha256-TbDUVCfqDXQmCwRgDW+hLZPfIElQAW2wFFgWOc3iKiU=";
    };

    # The actual python code is in this subdirectory
    sourceRoot = "${finalAttrs.src.name}/src/addon";

    # FIX: Patch the files to stop them from trying to write to the read-only Nix store
    postPatch = ''
      # 1. Stop the migration logic that runs on startup
      substituteInPlace __init__.py \
        --replace-fail "maybe_migrate_config(conf)" "pass # maybe_migrate_config(conf)"

      # 2. Stop the config manager from trying to save changes to disk
      substituteInPlace ankiaddonconfig/manager.py \
        --replace-fail "mw.addonManager.writeConfig(self.addon_dir, self._config)" "pass"
    '';

    # Inject our config into the build
    postInstall = ''
      cat > $out/config.json << 'EOF'
      ${builtins.toJSON recolorConfig}
      EOF
    '';
  });

  anki-hide-menu-bar = pkgs.stdenv.mkDerivation {
    pname = "anki-hide-menu-bar";
    version = "master";
    src = pkgs.fetchFromGitHub {
      owner = "abdnh";
      repo = "anki-hide-menu-bar";
      rev = "master";
      sha256 = "sha256-dyoPHPzS0O7dOxq7PDfHmjmZz7Qq9DIeHBcjls1BDRU=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

in
{
  home.packages = with pkgs; [
    (anki.withAddons [
      anki-connect
      review-heatmap
      anki-recolor
      anki-hide-menu-bar
    ])
  ];

  home.sessionVariables = {
    ANKI_WAYLAND = "1";
    ANKI_NOHIGHDPI = "0";
    QT_STYLE_OVERRIDE = "gtk2";
  };
}
