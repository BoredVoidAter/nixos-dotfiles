{ pkgs, config, lib, ... }:

let
  # Native messaging host definition for Vicinae
  vicinaeNativeMessaging = pkgs.runCommand "vicinae-native-messaging-host" { } ''
    mkdir -p $out/lib/mozilla/native-messaging-hosts
    cat > $out/lib/mozilla/native-messaging-hosts/com.vicinae.vicinae.json <<EOF
{
  "name": "com.vicinae.vicinae",
  "description": "Vicinae Native Messaging Host",
  "path": "${pkgs.vicinae}/libexec/vicinae/vicinae-browser-link",
  "type": "stdio",
  "allowed_extensions": [
    "firefox@vicinae.com",
    "vicinae@vicinae.com"
  ]
}
EOF
  '';
in
{
  programs.firefox = {
    enable = true;
    # Keep legacy path to match existing profile location and silence warning
    configPath = ".mozilla/firefox";
    nativeMessagingHosts = [ pkgs.keepassxc vicinaeNativeMessaging ];

    profiles."6tcs4h8d.default" = {
      settings = {
        "widget.gtk.rounded-bottom-corners.enabled" = false;
        "widget.wayland.opaque-region.enabled" = true;
        "extensions.enabledScopes" = 15;
        "extensions.autoDisableScopes" = 0;
        "extensions.installDistroAddons" = true;
        "extensions.vimium-c.excludedUrls" = "";
        "extensions.darkreader.theme" = "dark";
        "extensions.darkreader.brightness" = 100;
        "extensions.darkreader.contrast" = 100;
        "extensions.darkreader.sepia" = 0;
        "extensions.leechblockng.blockSets" = builtins.toJSON [
          {
            name = "Social Media Limit";
            enabled = true;
            timeLimit = {
              enabled = true;
              limitMinutes = 20;
              resetPeriod = "daily";
              blockAfterLimit = true;
              showCountdown = true;
              warningMinutes = 5;
            };
            sites = [
              "*://*.twitter.com/*"
              "*://*.x.com/*"
              "*://*.facebook.com/*"
              "*://*.instagram.com/*"
              "*://*.reddit.com/*"
              "*://*.youtube.com/*"
              "*://*.tiktok.com/*"
              "*://*.linkedin.com/*"
              "*://*.threads.net/*"
              "*://*.bluesky.social/*"
              "*://*.mastodon.social/*"
              "*://*.discord.com/*"
            ];
            wildcard = true;
            when = {
              enabled = true;
              days = [ 0 1 2 3 4 5 6 ]; # All days
              timeRange = "00:00-23:59";
            };
            blockMessage = "Daily 20-minute social media limit reached. Come back tomorrow! 🌱";
            lock = {
              enabled = false;
              password = "";
            };
          }
        ];
        "extensions.tampermonkey.scriptSync" = true;
      };
      extraConfig = ''
        user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
        user_pref("widget.wayland.opaque-region.enabled", true);
        user_pref("extensions.enabledScopes", 15);
        user_pref("extensions.autoDisableScopes", 0);
        user_pref("extensions.installDistroAddons", true);
      '';
    };
  };

  home.activation.betterfox = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for dir in ~/.mozilla/firefox/*.default*; do
      if [ -d "$dir" ] && [ -w "$dir" ]; then
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL --max-time 10 https://raw.githubusercontent.com/yokoffing/Betterfox/main/user.js -o "$dir/user.js" || true
        echo 'user_pref("widget.gtk.rounded-bottom-corners.enabled", false);' >> "$dir/user.js" 2>/dev/null || true
        echo 'user_pref("widget.wayland.opaque-region.enabled", true);' >> "$dir/user.js" 2>/dev/null || true
      fi
    done
  '';
}
