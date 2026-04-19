{ pkgs, ... }:

{

  home.packages = [ pkgs.firefoxpwa ];

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.keepassxc pkgs.firefoxpwa ];
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
      };
      DisablePocket = true;
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "keepassxc-browser@keepassxc.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
          installation_mode = "force_installed";
        };

        "my-youtube-recommendations@sblask" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/unhook/latest.xpi";
          installation_mode = "force_installed";
        };
        "{34daeb50-c2d2-4f14-886a-7160b24d66a4}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-shorts-block/latest.xpi";
          installation_mode = "force_installed";
        };
        "leechblockng@proginosko.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/leechblock-ng/latest.xpi";
          installation_mode = "force_installed";
        };
        "firefoxpwa@filips.si" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/pwas-for-firefox/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
    profiles.default = {
      id = 0;
      name = "Default";
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.startup.homepage" = "about:blank";
        "browser.search.region" = "DE";
        "ui.systemUsesDarkTheme" = 1;
        "network.trr.mode" = 3;
        "network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";
        "network.trr.bootstrapAddress" = "1.1.1.1";
      };
      userChrome = ''
        browser { background-color: #0D0D0D !important; }
      '';
    };
  };
}
