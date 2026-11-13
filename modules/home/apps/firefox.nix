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

  userChromeContent = ''
    :root {
      --toolbar-bgcolor: #131418 !important;
      --toolbar-color: #e6e6ea !important;
      --lwt-accent-color: #0d0e11 !important;
      --lwt-text-color: #e6e6ea !important;
      --arrowpanel-background: #0d0e11 !important;
      --arrowpanel-color: #e6e6ea !important;
      --arrowpanel-border-color: #27282f !important;
      --autocomplete-popup-background: #0d0e11 !important;
      --autocomplete-popup-color: #e6e6ea !important;
      --autocomplete-popup-highlight-background: #27282f !important;
      --chrome-content-separator-color: transparent !important;
      --focus-outline-color: #4c50bc !important;
      --toolbar-field-focus-border-color: #4c50bc !important;
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
    }

    ::selection, *::-moz-selection {
      background-color: #4c50bc !important;
      color: #ffffff !important;
    }

    #navigator-toolbox {
      background-color: #0d0e11 !important;
      border-bottom: 1px solid #1e1f25 !important;
    }

    #nav-bar {
      background-color: #131418 !important;
      box-shadow: none !important;
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
    }

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

    /* Megabar expansion & search results dropdown */
    #urlbar[open] > #urlbar-background,
    #urlbar[open] > .urlbar-background,
    #urlbar[breakout][breakout-extend] > #urlbar-background,
    #urlbar[breakout][breakout-extend] > .urlbar-background,
    #urlbar[breakout][breakout-extend] > #urlbar-input-container,
    #urlbar-results,
    #urlbarView-results,
    .urlbarView,
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

    /* Tab bar styling with purple accent */
    tab {
      font-family: "JetBrainsMono Nerd Font", monospace !important;
      font-size: 12px !important;
    }

    .tab-background {
      border-radius: 8px !important;
      margin-block: 4px !important;
    }

    .tabbrowser-tab[selected="true"] .tab-background {
      background-color: #18191e !important;
      border: 1px solid #3a3c48 !important;
      border-bottom: 2px solid #4c50bc !important;
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

    .tabbrowser-tab:not([selected="true"]) .tab-close-button {
      display: none !important;
    }

    #PersonalToolbar {
      background-color: #131418 !important;
      color: #e6e6ea !important;
      border-bottom: 1px solid #1e1f25 !important;
    }

    findbar {
      background-color: #131418 !important;
      border-top: 1px solid #2c2d35 !important;
      color: #e6e6ea !important;
      border-radius: 8px 8px 0 0 !important;
    }
  '';

  userContentContent = ''
    @-moz-document url("about:home"), url("about:newtab"), url("about:blank"), url("about:privatebrowsing") {
      body, #root, .activity-stream, .outer-wrapper {
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
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    nativeMessagingHosts = [ pkgs.keepassxc vicinaeNativeMessaging ];

    profiles."6tcs4h8d.default" = {
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.drawInTitlebar" = true;
        "browser.theme.toolbar-theme" = 0;
        "browser.theme.content-theme" = 0;
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

      userChrome = userChromeContent;
      userContent = userContentContent;

      extraConfig = ''
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("widget.non-native-theme.gtk.accent-color", "#4c50bc");
        user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
        user_pref("widget.wayland.opaque-region.enabled", true);
        user_pref("browser.theme.toolbar-theme", 0);
        user_pref("browser.theme.content-theme", 0);
        user_pref("extensions.enabledScopes", 15);
        user_pref("extensions.autoDisableScopes", 0);
        user_pref("extensions.installDistroAddons", true);
      '';
    };
  };

  # Copy userChrome.css and userContent.css to chrome directory of all profile folders
  home.activation.firefoxCustomCss = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for dir in ~/.mozilla/firefox/*; do
      if [ -d "$dir" ] && ([ -f "$dir/prefs.js" ] || [[ "$dir" == *default* ]]); then
        mkdir -p "$dir/chrome"
        cp -f ${userChromeFile} "$dir/chrome/userChrome.css"
        cp -f ${userContentFile} "$dir/chrome/userContent.css"
      fi
    done
  '';
}
