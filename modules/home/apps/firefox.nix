{ pkgs, config, lib, ... }:

let
  # Create Firefox extension packages using fetchFirefoxAddon
  vimiumC = pkgs.fetchFirefoxAddon {
    name = "vimium-c";
    url = "https://addons.mozilla.org/firefox/downloads/file/4474326/vimium_c-2.12.3.xpi";
    sha256 = "sha256:e1a4f8cc13791dfb985c2a78d33df1e8a40f23bd6eca9217165cb748009df540";
    fixedExtid = "vimium-c@gdh1995.cn";
  };

  tampermonkey = pkgs.fetchFirefoxAddon {
    name = "tampermonkey";
    url = "https://addons.mozilla.org/firefox/downloads/file/4797143/tampermonkey-5.5.0.xpi";
    sha256 = "sha256:190031c78dbc5696114835601f2c8e6b855ad1e134df5df278f8fc158c065908";
    fixedExtid = "firefox@tampermonkey.net";
  };

  darkReader = pkgs.fetchFirefoxAddon {
    name = "darkreader";
    url = "https://addons.mozilla.org/firefox/downloads/file/5055786/darkreader-4.9.133.xpi";
    sha256 = "sha256:eb06c5096d761616c7f1d954c11524ca4bff4fe7229044dc1fce288a8c0853ab";
    fixedExtid = "addon@darkreader.org";
  };

  leechBlockNG = pkgs.fetchFirefoxAddon {
    name = "leechblock-ng";
    url = "https://addons.mozilla.org/firefox/downloads/file/5063822/leechblock_ng-1.8.xpi";
    sha256 = "sha256:4548328caa620ea53bfb71b01bfa59527cef5e18ad9926d7691d8600d8ac6e13";
    fixedExtid = "leechblockng@proginosko.com";
  };

  vicinaeExt = pkgs.fetchFirefoxAddon {
    name = "vicinae";
    url = "https://addons.mozilla.org/firefox/downloads/file/5154581/vicinae-1.1.xpi";
    sha256 = "sha256:0015b61e3e5716c0512729ed380a0332d0ca1330b1cc84221d1d786e87d9b3e8";
    fixedExtid = "firefox@vicinae.com";
  };

  # All extensions to install
  firefoxExtensions = [
    vimiumC
    tampermonkey
    darkReader
    leechBlockNG
    vicinaeExt
  ];

  # Vicinae native messaging host wrapper
  # The vicinae package provides a native messaging host but with a broken path in the manifest.
  # This wrapper creates a proper manifest in the standard location.
  vicinaeNativeMessaging = pkgs.writeShellScriptBin "vicinae-native-messaging-host" ''
    mkdir -p $out/lib/mozilla/native-messaging-hosts
    cat > $out/lib/mozilla/native-messaging-hosts/com.vicinae.vicinae.json <<EOF
{
  "name": "com.vicinae.vicinae",
  "description": "Vicinae Native Messaging Host",
  "path": "${pkgs.vicinae}/libexec/vicinae/vicinae-browser-link",
  "type": "stdio",
  "allowed_extensions": [
    "firefox@vicinae.com"
  ]
}
EOF
  '';

  # Betterfox user.js configuration
  betterfoxConfig = ''
    # Betterfox preferences
    user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
    user_pref("widget.wayland.opaque-region.enabled", true);

    # Ensure extensions are enabled
    user_pref("extensions.enabledScopes", 15);
    user_pref("extensions.installDistroAddons", true);
  '';

in
{
  # Configure Firefox with declarative extensions
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    nativeMessagingHosts = [ pkgs.keepassxc vicinaeNativeMessaging ];

    # Configure profiles with our preferences
    profiles.default = {
      # Install extensions declaratively (per-profile)
      extensions = {
        packages = firefoxExtensions;
        force = true;
      };
      # About:config style preferences (will be locked)
      settings = {
        # Betterfox preferences
        "widget.gtk.rounded-bottom-corners.enabled" = false;
        "widget.wayland.opaque-region.enabled" = true;

        # Ensure extensions are enabled
        "extensions.enabledScopes" = 15;
        "extensions.installDistroAddons" = true;

        # Vimium C preferences
        "extensions.vimium-c.excludedUrls" = "";

        # Dark Reader preferences
        "extensions.darkreader.theme" = "dark";
        "extensions.darkreader.brightness" = 100;
        "extensions.darkreader.contrast" = 100;
        "extensions.darkreader.sepia" = 0;

        # LeechBlock NG preferences
        "extensions.leechblockng.blockSets" = "[]";

        # Tampermonkey preferences
        "extensions.tampermonkey.scriptSync" = true;
      };

      # Extra user.js configuration (for things not supported by settings)
      extraConfig = ''
        # Betterfox preferences (additional)
        user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
        user_pref("widget.wayland.opaque-region.enabled", true);

        # Ensure extensions are enabled
        user_pref("extensions.enabledScopes", 15);
        user_pref("extensions.installDistroAddons", true);
      '';
    };
  };

  # Also apply Betterfox user.js to any existing profiles (activation script)
  home.activation.betterfox = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for dir in ~/.mozilla/firefox/*.default*; do
      if [ -d "$dir" ]; then
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -sL https://raw.githubusercontent.com/yokoffing/Betterfox/main/user.js -o "$dir/user.js"
        echo 'user_pref("widget.gtk.rounded-bottom-corners.enabled", false);' >> "$dir/user.js"
        echo 'user_pref("widget.wayland.opaque-region.enabled", true);' >> "$dir/user.js"
      fi
    done
  '';
}