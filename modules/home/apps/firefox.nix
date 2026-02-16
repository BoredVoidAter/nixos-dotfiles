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
            # Block Set 1: Social Media Limit (30 mins/day)
            setName1 = "Social Media Limit";
            sites1 = "facebook.com instagram.com reddit.com tiktok.com twitter.com x.com youtube.com";
            
            # Use 2359 to be safe with parsing
            times1 = "0000-2359";
            
            # 30 Minutes allowed per 24 hours (86400 seconds)
            limitMins1 = "30";
            limitPeriod1 = "86400"; 
            
            days1 = "127"; # Everyday
            blockURL1 = "blocked.html?$S&$U";
            
            # --- SECURITY & ANTI-OVERRIDE ---
            # 1 = Require password for Options page only
            # (We disable the Override button entirely below, so no need to password protect the button)
            passwordRequire1 = "1"; 
            
            # A static random hash acting as the password. 
            # Since you don't know it, you can't unlock Options without editing this file.
            passwordSetSpec1 = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918";
            
            # Disables the "Override" button on the block page completely.
            allowOverride1 = false;
            
            # Prevents you from changing these settings while the block is active.
            allowOverLock1 = false;

            # --- BEHAVIOR ---
            # Delay Blocking = True means "Allow access for limitMins"
            delayFirst1 = true;
            delayFirstMode1 = "0"; # 0 = Use limitMins1 as the budget
            delayAllowMins1 = "30"; # Explicitly reiterate the 30 min budget
            
            countFocus1 = true; # Only count time when the tab is actually active
            countAudio1 = false;
            
            # Standard boilerplate to keep other slots empty
            rollover1 = false;
            conjMode1 = false;
            customMsg1 = "";
            incogMode1 = "0";
            activeTabMode1 = "0";
            applyFilter1 = false;
            filterName1 = "grayscale";
            filterMute1 = false;
            filterCustom1 = "";
            closeTab1 = false;
            activeBlock1 = true;
            minBlock1 = "";
            showKeyword1 = true;
            titleOnly1 = false;
            delaySecs1 = "60";
            delayAutoLoad1 = true;
            delayCancel1 = true;
            reloadSecs1 = "";
            addHistory1 = false;
            prevOpts1 = false;
            prevGenOpts1 = false;
            prevAddons1 = false;
            prevSupport1 = false;
            prevProfiles1 = false;
            prevDebugging1 = false;
            prevOverride1 = false;
            disable1 = false;
            showTimer1 = true;
            allowRefers1 = false;
            allowKeywords1 = false;
            waitSecs1 = "";
            sitesURL1 = "";
            regexpBlock1 = "";
            regexpAllow1 = "";
            regexpKeyword1 = "";
            ignoreHash1 = true;
            limitOffset1 = "";

            setName2 = ""; sites2 = ""; times2 = ""; limitMins2 = ""; limitPeriod2 = ""; days2 = "62"; activeBlock2 = false; disable2 = false;
            setName3 = ""; sites3 = ""; times3 = ""; limitMins3 = ""; limitPeriod3 = ""; days3 = "62"; activeBlock3 = false; disable3 = false;
            setName4 = ""; sites4 = ""; times4 = ""; limitMins4 = ""; limitPeriod4 = ""; days4 = "62"; activeBlock4 = false; disable4 = false;
            setName5 = ""; sites5 = ""; times5 = ""; limitMins5 = ""; limitPeriod5 = ""; days5 = "62"; activeBlock5 = false; disable5 = false;
            setName6 = ""; sites6 = ""; times6 = ""; limitMins6 = ""; limitPeriod6 = ""; days6 = "62"; activeBlock6 = false; disable6 = false;
            
            numSets = "6";
            sync = false;
            theme = "";
            customStyle = "";
            oa = "0";
            hpp = true;
            apt = "";
            timerVisible = true;
            timerSize = "1";
            timerLocation = "0";
            timerMaxHours = "24";
            timerBadge = true;
            orm = "";
            orln = "";
            orlp = "";
            ora = "0";
            orcode = "";
            orc = true;
            warnSecs = "";
            warnImmediate = true;
            contextMenu = true;
            matchSubdomains = false;
            disableLink = false;
            clockTimeFormat = "0";
            saveSecs = "10";
            clockOffset = "";
            ignoreJumpSecs = "";
            allFocused = false;
            useDocFocus = true;
            processTabsSecs = "1";
            processActiveTabs = false;
            accessCodeImage = false;
            allowLBWebsite = true;
            diagMode = false;
            exportPasswords = false;
            autoExportSync = true;
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
