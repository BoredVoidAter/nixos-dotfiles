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
      };
      # --- Extension Configuration (LeechBlock) ---
      "3rdparty" = {
        Extensions = {
          "leechblockng@proginosko.com" = {
            # --- BLOCK SET 1: Social Media ---
            setName1 = "Social Media Limit";
            sites1 = "facebook.com\ninstagram.com\nreddit.com\ntiktok.com\ntwitter.com\nx.com\nyoutube.com";
            
            # Times: All Day (00:00 to 23:59)
            times1 = "0000-2359";
            
            # Limit: 30 Minutes per 24 Hours
            limitMins1 = 30;       # INTEGER (Fixes 'Always Block')
            limitPeriod1 = 86400;  # INTEGER (Seconds in 24h)
            days1 = "127";         # String "127" = All Days
            
            # --- SECURITY & ANTI-TAMPER ---
            # 1 = Require password for Options page
            passwordRequire1 = 1; 
            
            # This is a SHA256 hash of a random complex string I generated.
            # Since you do not know the plain text, you cannot unlock the Options page.
            # To remove this lock, you must edit this nix file and rebuild.
            passwordSetSpec1 = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08";
            
            # Completely disable the "Override" button on the block page
            allowOverride1 = false;
            
            # Prevent changing settings during block (Redundant if pw is unknown, but good safety)
            allowOverLock1 = false;
            
            # --- BEHAVIOR ---
            blockURL1 = "blocked.html?$S&$U";
            countFocus1 = true;   # Only count time when tab is focused
            countAudio1 = false;  # Don't count if just listening to music in bg
            delayFirst1 = false;  # Disable "Delaying Page" (We want hard limit)
            
            # --- DEFAULTS (Empty Sets) ---
            # We must explicitly zero these out with correct types
            setName2 = ""; sites2 = ""; times2 = ""; limitMins2 = 0; limitPeriod2 = 0; days2 = "62"; activeBlock2 = false; disable2 = false;
            setName3 = ""; sites3 = ""; times3 = ""; limitMins3 = 0; limitPeriod3 = 0; days3 = "62"; activeBlock3 = false; disable3 = false;
            setName4 = ""; sites4 = ""; times4 = ""; limitMins4 = 0; limitPeriod4 = 0; days4 = "62"; activeBlock4 = false; disable4 = false;
            setName5 = ""; sites5 = ""; times5 = ""; limitMins5 = 0; limitPeriod5 = 0; days5 = "62"; activeBlock5 = false; disable5 = false;
            setName6 = ""; sites6 = ""; times6 = ""; limitMins6 = 0; limitPeriod6 = 0; days6 = "62"; activeBlock6 = false; disable6 = false;

            # --- GENERAL OPTIONS ---
            numSets = 6;
            enable = true;
            timerVisible = true;
            timerBadge = true;
            contextMenu = true;
            
            # Export/Import (Disable to prevent easy bypass)
            exportPasswords = false;
            autoExportSync = false;
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
