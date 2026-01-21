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