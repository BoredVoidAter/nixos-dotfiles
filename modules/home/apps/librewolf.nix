{ pkgs, config, lib, vicinae, ... }:

let
  vicinaePkg = vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;

  userChromeContent = ''
    :root {
      --toolbar-bgcolor: #131418 !important;
      --toolbar-color: #e6e6ea !important;
      --lwt-accent-color: #0d0e11 !important;
      --lwt-text-color: #e6e6ea !important;
      --toolbox-bgcolor: #0d0e11 !important;
      --toolbox-bgcolor-inactive: #0d0e11 !important;
      --tabs-navbar-separator-color: #1e1f25 !important;
      --arrowpanel-background: #0d0e11 !important;
      --arrowpanel-color: #e6e6ea !important;
      --arrowpanel-border-color: #27282f !important;
      --panel-background: #0d0e11 !important;
      --panel-color: #e6e6ea !important;
      --panel-border-color: #27282f !important;
      --button-hover-bgcolor: #18191e !important;
      --button-active-bgcolor: #27282f !important;
      --autocomplete-popup-background: #0d0e11 !important;
      --autocomplete-popup-color: #e6e6ea !important;
      --autocomplete-popup-highlight-background: #27282f !important;
      --chrome-content-separator-color: transparent !important;
      --focus-outline-color: #4c50bc !important;
      --toolbar-field-focus-border-color: #4c50bc !important;
      --toolbar-field-border-color: #27282f !important;
      --accent-color: #4c50bc !important;
      --toolbar-field-background-color: #0d0e11 !important;
      --toolbar-field-focus-background-color: #0d0e11 !important;
      --toolbar-field-color: #e6e6ea !important;
      --toolbar-field-focus-color: #ffffff !important;
      --lwt-toolbar-field-background-color: #0d0e11 !important;
      --lwt-toolbar-field-focus: #0d0e11 !important;
      --lwt-toolbar-field-color: #e6e6ea !important;
      --lwt-toolbar-field-focus-color: #ffffff !important;
      --urlbar-box-bgcolor: #0d0e11 !important;
      --urlbar-box-hover-bgcolor: #18191e !important;
      --urlbar-box-focus-bgcolor: #0d0e11 !important;
      --urlbar-popup-url-color: #4c50bc !important;
      --urlbar-popup-action-color: #4c50bc !important;
      --tab-selected-bgcolor: #18191e !important;
      --tab-hover-background-color: #18191e !important;
      --sidebar-background-color: #0d0e11 !important;
      --sidebar-text-color: #e6e6ea !important;
      --sidebar-border-color: #1e1f25 !important;
    }

    ::selection, *::-moz-selection {
      background-color: #4c50bc !important;
      color: #ffffff !important;
    }

    /* Strip window controls, spacers, and redundant navigation/action buttons */
    .titlebar-buttonbox-container,
    .titlebar-spacer,
    #back-button,
    #forward-button,
    #stop-reload-button,
    #reload-button,
    #stop-button,
    #home-button,
    #downloads-button,
    #library-button,
    #fxa-toolbar-menu-button,
    #sidebar-button,
    #firefox-view-button,
    #PanelUI-button,
    #new-tab-button,
    #tabs-newtab-button,
    #alltabs-button,
    #private-browsing-indicator-with-label,
    .tab-close-button,
    #star-button-box,
    #reader-mode-button,
    #picture-in-picture-button,
    #translations-button,
    #pageActionButton,
    #tracking-protection-icon-container,
    toolbarspring {
      display: none !important;
    }

    #main-window,
    #browser,
    #tabbrowser-tabpanels,
    #TabsToolbar,
    #titlebar {
      background-color: #0d0e11 !important;
    }

    #navigator-toolbox {
      background-color: #0d0e11 !important;
      border-bottom: 1px solid #1e1f25 !important;
    }

    #nav-bar {
      background-color: #131418 !important;
      box-shadow: none !important;
      padding: 2px 6px !important;
    }

    /* Force all URL and search input layers to #0d0e11, stripping GTK #333333 */
    #urlbar,
    #urlbar * {
      --toolbar-field-background-color: #0d0e11 !important;
      --toolbar-field-focus-background-color: #0d0e11 !important;
      --lwt-toolbar-field-background-color: #0d0e11 !important;
      --lwt-toolbar-field-focus: #0d0e11 !important;
      --urlbar-box-bgcolor: #0d0e11 !important;
    }

    #urlbar,
    #urlbar-background,
    .urlbar-background,
    #urlbar-input-container,
    .urlbar-input-container,
    .urlbar-input,
    .urlbar-input-box,
    #urlbar-input,
    #searchbar,
    .searchbar-textbox,
    input.textbox-input {
      appearance: none !important;
      -moz-appearance: none !important;
      background-color: #0d0e11 !important;
      background: #0d0e11 !important;
      border-color: #27282f !important;
      color: #e6e6ea !important;
    }

    #urlbar-background,
    .urlbar-background,
    #searchbar,
    .searchbar-textbox {
      border: 1px solid #27282f !important;
      border-radius: 8px !important;
      box-shadow: none !important;
    }

    #urlbar[focused] > #urlbar-background,
    #urlbar[focused] > .urlbar-background,
    #urlbar[focused="true"] > #urlbar-background,
    #urlbar[focused="true"] > .urlbar-background,
    #searchbar:focus-within {
      border-color: #4c50bc !important;
      box-shadow: 0 0 0 1px #4c50bc !important;
    }

    #urlbar-input, .searchbar-textbox {
      font-family: "JetBrainsMono Nerd Font", monospace !important;
      font-size: 13px !important;
    }

    #identity-box {
      background-color: transparent !important;
      color: #b5b7c0 !important;
    }

    #identity-box:hover {
      background-color: #18191e !important;
      border-radius: 6px !important;
    }

    #urlbar-search-mode-indicator {
      background-color: #4c50bc !important;
      color: #ffffff !important;
      border-radius: 6px !important;
    }

    /* Megabar expansion & search results dropdown */
    #urlbar[open] > #urlbar-background,
    #urlbar[open] > .urlbar-background,
    #urlbar[breakout][breakout-extend] > #urlbar-background,
    #urlbar[breakout][breakout-extend] > .urlbar-background,
    #urlbar[breakout][breakout-extend] > #urlbar-input-container,
    #urlbar-results,
    #urlbarView-results,
    .urlbarView,
    .urlbarView-body-outer,
    .urlbarView-body-inner,
    .urlbarView-results,
    .search-one-offs,
    .search-panel-one-offs-header {
      appearance: none !important;
      -moz-appearance: none !important;
      background-color: #0d0e11 !important;
      background: #0d0e11 !important;
      border-color: #4c50bc !important;
      color: #e6e6ea !important;
    }

    .urlbarView-row,
    .urlbarView-row-inner {
      appearance: none !important;
      -moz-appearance: none !important;
      background-color: #0d0e11 !important;
      background: #0d0e11 !important;
      border-radius: 6px !important;
    }

    .urlbarView-row:hover,
    .urlbarView-row:hover .urlbarView-row-inner {
      background-color: #18191e !important;
      background: #18191e !important;
    }

    .urlbarView-row[selected],
    .urlbarView-row[selected] .urlbarView-row-inner {
      background-color: #27282f !important;
      background: #27282f !important;
    }

    .urlbarView-row[selected] .urlbarView-title {
      color: #ffffff !important;
    }

    /* Query match highlights in purple #4c50bc */
    .urlbarView-title strong,
    .urlbarView-url strong {
      color: #4c50bc !important;
      font-weight: 600 !important;
    }

    .urlbarView-row .urlbarView-action,
    .urlbarView-type-icon {
      color: #4c50bc !important;
      fill: #4c50bc !important;
    }

    .search-one-offs .searchbar-engine-one-off-item:hover {
      background-color: #18191e !important;
    }

    .search-one-offs .searchbar-engine-one-off-item[selected] {
      background-color: #4c50bc !important;
    }

    /* Compact tab bar with purple accent */
    tab {
      font-family: "JetBrainsMono Nerd Font", monospace !important;
      font-size: 12px !important;
    }

    .tab-background {
      border-radius: 8px !important;
      margin-block: 3px !important;
      box-shadow: none !important;
    }

    .tabbrowser-tab[selected="true"] .tab-background {
      background-color: #18191e !important;
      border: 1px solid #3a3c48 !important;
      border-bottom: 2px solid #4c50bc !important;
      box-shadow: none !important;
    }

    .tabbrowser-tab:hover:not([selected="true"]) .tab-background {
      background-color: #18191e !important;
    }

    .tab-label {
      color: #b5b7c0 !important;
    }

    .tabbrowser-tab[selected="true"] .tab-label {
      color: #ffffff !important;
      font-weight: 500 !important;
    }

    /* Sidebar & vertical tabs */
    #sidebar-box,
    #sidebar-header,
    #sidebar-main,
    sidebar-main {
      background-color: #0d0e11 !important;
      color: #e6e6ea !important;
      border-color: #1e1f25 !important;
    }

    /* Popups & context menus */
    menupopup,
    panel,
    .panel-subview-body,
    panelview {
      --arrowpanel-background: #0d0e11 !important;
      --arrowpanel-color: #e6e6ea !important;
      --arrowpanel-border-color: #27282f !important;
      --panel-background: #0d0e11 !important;
      --panel-color: #e6e6ea !important;
      --panel-border-color: #27282f !important;
      background-color: #0d0e11 !important;
      color: #e6e6ea !important;
      border-color: #27282f !important;
    }

    menuitem:hover,
    menu:hover,
    .subviewbutton:hover {
      background-color: #18191e !important;
    }

    #PersonalToolbar {
      background-color: #131418 !important;
      color: #e6e6ea !important;
      border-bottom: 1px solid #1e1f25 !important;
    }

    #statuspanel-label {
      background-color: #131418 !important;
      color: #e6e6ea !important;
      border: 1px solid #27282f !important;
      border-radius: 6px !important;
    }

    findbar {
      background-color: #131418 !important;
      border-top: 1px solid #2c2d35 !important;
      color: #e6e6ea !important;
      border-radius: 8px 8px 0 0 !important;
    }

    findbar textbox:focus {
      outline: 1px solid #4c50bc !important;
    }
  '';

  userContentContent = ''
    @-moz-document url("about:home"), url("about:newtab"), url("about:blank"), url("about:privatebrowsing") {
      html, html.private, body, #root, .activity-stream, .outer-wrapper, .private-browsing-container {
        background-color: #0d0e11 !important;
        background: #0d0e11 !important;
        color: #e6e6ea !important;
      }
      .search-inner-wrapper,
      .search-handoff-button,
      .search-wrapper .search-handoff-button,
      input[type="search"],
      .search-wrapper input {
        appearance: none !important;
        -moz-appearance: none !important;
        background-color: #0d0e11 !important;
        background: #0d0e11 !important;
        border: 1px solid #27282f !important;
        color: #e6e6ea !important;
        border-radius: 8px !important;
      }
      .search-inner-wrapper:focus-within,
      .search-handoff-button:focus,
      .search-wrapper .search-handoff-button:focus,
      input[type="search"]:focus,
      .search-wrapper input:focus {
        border-color: #4c50bc !important;
        box-shadow: 0 0 0 1px #4c50bc !important;
      }
    }
  '';

  userChromeFile = pkgs.writeText "userChrome.css" userChromeContent;
  userContentFile = pkgs.writeText "userContent.css" userContentContent;
in
{
  programs.librewolf = {
    enable = true;
    nativeMessagingHosts = [ vicinaePkg ];

    policies = {
      DisableAppUpdate = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
      };
      ExtensionSettings = {
        "*".installation_mode = "allowed";

        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "vimium-c@gdh1995.cn" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
        };
        "firefox@tampermonkey.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
        };
        "addon@darkreader.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
        };
        "leechblockng@proginosko.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/leechblock-ng/latest.xpi";
        };
        "firefox@vicinae.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vicinae/latest.xpi";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          private_browsing = true;
        };
      };
    };

    profiles.default = {
      id = 0;
      isDefault = true;

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.drawInTitlebar" = true;
        "browser.tabs.inTitlebar" = 1;
        "browser.uidensity" = 1;
        "browser.compactmode.show" = true;
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.tabs.tabmanager.enabled" = false;
        "sidebar.revamp" = false;
        "browser.theme.toolbar-theme" = 0;
        "browser.theme.content-theme" = 0;
        "ui.systemUsesDarkTheme" = 1;
        "widget.non-native-theme.gtk.accent-color" = "#4c50bc";
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
              days = [ 0 1 2 3 4 5 6 ];
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

      userChrome = userChromeContent;
      userContent = userContentContent;

      extraConfig = ''
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("widget.non-native-theme.gtk.accent-color", "#4c50bc");
        user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
        user_pref("widget.wayland.opaque-region.enabled", true);
        user_pref("browser.theme.toolbar-theme", 0);
        user_pref("browser.theme.content-theme", 0);
        user_pref("ui.systemUsesDarkTheme", 1);
        user_pref("browser.uidensity", 1);
        user_pref("browser.toolbars.bookmarks.visibility", "never");
        user_pref("browser.tabs.tabmanager.enabled", false);
        user_pref("sidebar.revamp", false);
        user_pref("extensions.enabledScopes", 15);
        user_pref("extensions.autoDisableScopes", 0);
        user_pref("extensions.installDistroAddons", true);
      '';
    };
  };

  # Ensure userChrome.css and userContent.css are applied to any extra/imported LibreWolf profiles
  home.activation.librewolfCustomCss = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for dir in ~/.librewolf/*; do
      if [ -d "$dir" ] && [ ! -L "$dir/chrome/userChrome.css" ] && ([ -f "$dir/prefs.js" ] || [[ "$dir" == *default* ]]); then
        mkdir -p "$dir/chrome"
        cp -f ${userChromeFile} "$dir/chrome/userChrome.css"
        cp -f ${userContentFile} "$dir/chrome/userContent.css"
      fi
    done
  '';
}
