{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.keepassxc ];
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = { Value = true; Locked = true; };
      DisablePocket = true;
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"; installation_mode = "force_installed"; };
        "keepassxc-browser@keepassxc.org" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi"; installation_mode = "force_installed"; };
        "tokyo-night-dark-theme" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/tokyo-night-dark-theme/latest.xpi"; installation_mode = "force_installed"; };
        "my-youtube-recommendations@sblask" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/unhook/latest.xpi"; installation_mode = "force_installed"; };
        "{34daeb50-c2d2-4f14-886a-7160b24d66a4}" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-shorts-block/latest.xpi"; installation_mode = "force_installed"; };
        
        # LeechBlock is force-installed. You CANNOT remove or disable it from about:addons.
        "leechblockng@proginosko.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/leechblock-ng/latest.xpi";
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
      };
      userChrome = "browser { background-color: #1a1b26 !important; }";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" =[ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" =[ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };
}
