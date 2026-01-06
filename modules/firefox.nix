{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.keepassxc ];

    # Policies allow us to install extensions without creating complex derivations
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
      };
      DisablePocket = true;
      
      # Extension Management
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        # KeePassXC-Browser
        "keepassxc-browser@keepassxc.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
          installation_mode = "force_installed";
        };
        # Tokyo Night Theme (Official or popular one)
        "{4c878e12-32b2-4cd8-89c0-82c813de2d10}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tokyo-night-milav/latest.xpi";
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
        "ui.systemUsesDarkTheme" = 1; # Force dark internal pages
      };
      
      # Optional: Hardcode CSS for total UI integration if the extension isn't enough
      userChrome = ''
        /* Force dark background on loading pages */
        browser { background-color: #1a1b26 !important; }
      '';
    };
  };
}
