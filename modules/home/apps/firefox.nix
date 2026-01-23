{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.keepassxc ];

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
      };
      DisablePocket = true;
      
      # --- Extension Installation ---
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "keepassxc-browser@keepassxc.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
          installation_mode = "force_installed";
        };
        "tokyo-night-dark-theme" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tokyo-night-dark-theme/latest.xpi";
          installation_mode = "force_installed";
        };

        # FIXED: Correct ID for "Unhook - Remove YouTube Recommended Videos"
        "my-youtube-recommendations@sblask" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/unhook/latest.xpi";
          installation_mode = "force_installed";
        };

        "leechblockng@proginosko.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/leechblock-ng/latest.xpi";
          installation_mode = "force_installed";
        };
      };

      # --- Extension Configuration (LeechBlock) ---
      # This injects settings directly into LeechBlock's managed storage.
      "3rdparty" = {
        "Extensions" = {
          "leechblockng@proginosko.com" = {
            # Block Set 1: Social Media (30 mins/day)
            "blockSet1" = {
              "name" = "Social Media Limit";
              # Sites to block (domains separated by + or newlines)
              "siteString" = "youtube.com\ninstagram.com\ntwitter.com\nx.com\nfacebook.com\ntiktok.com\nreddit.com";
              # 30 minutes allowed
              "timeLimit" = 30;
              # Reset limit every day
              "timePeriod" = 1440; 
              # Apply to all days (0=Sun, 1=Mon, ..., 6=Sat)
              "days" = "0123456"; 
              # Active all day (0000 to 2400)
              "activeTimes" = "0000-2400"; 
            };
            
            # Optional: Lockdown settings or general options
            "showIcon" = true;
            "showCount" = true;
          };
        };
      };
    };

    profiles = {
      default = {
        id = 0;
        name = "Default";
        isDefault = true;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.startup.homepage" = "about:blank";
          "browser.search.region" = "DE";
          "ui.systemUsesDarkTheme" = 1;
        };
        userChrome = ''
          /* Force dark background on loading pages */
          browser { background-color: #1a1b26 !important; }
        '';
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };
}
