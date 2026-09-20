{ pkgs, lib, ... }:

let
  wikipediaNotionSvg = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/e/e9/Notion-logo.svg";
    curlOptsList = [ "-H" "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" ];
    sha256 = "sha256-G1KhhdgWbZM59cFt1ReJ7jD0mmW01Ac4KQtgQj4zEWA=";
  };

  notionPng = pkgs.runCommand "notion.png" { } ''
    ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${wikipediaNotionSvg} $out
  '';

  packageJson = pkgs.writeText "package.json" ''
    {
      "name": "notion-app",
      "version": "1.0.0",
      "main": "main.js"
    }
  '';

  mainJs = pkgs.writeText "main.js" ''
    const { app, BrowserWindow, shell, session } = require("electron");
    const path = require("path");

    app.name = "notion-app";

    const USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36";
    app.userAgentFallback = USER_AGENT;

    app.commandLine.appendSwitch("disable-blink-features", "AutomationControlled");
    app.commandLine.appendSwitch("ozone-platform-hint", "auto");
    app.commandLine.appendSwitch("enable-features", "UseOzonePlatform,WaylandWindowDecorations");

    app.setAsDefaultProtocolClient("notion");

    const gotTheLock = app.requestSingleInstanceLock();
    let mainWindow = null;

    function normalizeUrl(rawUrl) {
      if (!rawUrl) return "https://www.notion.so";
      if (rawUrl.startsWith("notion://")) {
        const stripped = rawUrl.replace(/^notion:\/\//, "");
        if (stripped.startsWith("http://") || stripped.startsWith("https://")) {
          return stripped;
        }
        if (
          stripped.startsWith("www.notion.so") ||
          stripped.startsWith("notion.so") ||
          stripped.startsWith("www.notion.com") ||
          stripped.startsWith("notion.com")
        ) {
          return "https://" + stripped;
        }
        return "https://www.notion.so/" + stripped.replace(/^\//, "");
      }
      return rawUrl;
    }

    function isInternalOrAuthUrl(rawUrl) {
      if (!rawUrl || rawUrl === "" || rawUrl === "about:blank") return true;
      if (rawUrl.startsWith("notion://") || rawUrl.startsWith("/")) return true;
      try {
        const parsed = new URL(rawUrl, "https://www.notion.so");
        const host = parsed.hostname.toLowerCase();
        return (
          host === "notion.so" ||
          host.endsWith(".notion.so") ||
          host === "notion.com" ||
          host.endsWith(".notion.com") ||
          host === "notion.site" ||
          host.endsWith(".notion.site") ||
          host === "notion.new" ||
          host.endsWith(".notion.new") ||
          host === "google.com" ||
          host.endsWith(".google.com") ||
          host.endsWith(".google.de") ||
          host.includes("google.") ||
          host.endsWith(".gstatic.com") ||
          host.endsWith(".googleapis.com") ||
          host.endsWith(".googleusercontent.com") ||
          host.endsWith(".apple.com") ||
          host.endsWith(".microsoft.com") ||
          host.endsWith(".microsoftonline.com") ||
          host.endsWith(".live.com") ||
          host.endsWith(".msftauth.net") ||
          host.endsWith(".cloudflare.com") ||
          host.endsWith(".turnstile.com") ||
          host.endsWith(".challenges.cloudflare.com") ||
          host.endsWith(".hcaptcha.com") ||
          host.endsWith(".recaptcha.net") ||
          host.endsWith(".okta.com") ||
          host.endsWith(".auth0.com") ||
          host.endsWith(".onelogin.com") ||
          host.endsWith(".duosecurity.com")
        );
      } catch (e) {
        return false;
      }
    }

    if (!gotTheLock) {
      app.quit();
    } else {
      app.on("second-instance", (event, commandLine) => {
        if (mainWindow) {
          if (mainWindow.isMinimized()) mainWindow.restore();
          mainWindow.focus();

          const targetUrl = commandLine.find(arg =>
            arg.startsWith("http://") ||
            arg.startsWith("https://") ||
            arg.startsWith("notion://")
          );
          if (targetUrl) {
            mainWindow.loadURL(normalizeUrl(targetUrl));
          }
        }
      });

      app.whenReady().then(() => {
        session.defaultSession.setUserAgent(USER_AGENT);

        session.defaultSession.webRequest.onBeforeSendHeaders((details, callback) => {
          delete details.requestHeaders["user-agent"];
          delete details.requestHeaders["User-Agent"];
          delete details.requestHeaders["sec-ch-ua"];
          delete details.requestHeaders["sec-ch-ua-mobile"];
          delete details.requestHeaders["sec-ch-ua-platform"];
          delete details.requestHeaders["sec-ch-ua-model"];
          delete details.requestHeaders["sec-ch-ua-platform-version"];
          details.requestHeaders["User-Agent"] = USER_AGENT;
          callback({ cancel: false, requestHeaders: details.requestHeaders });
        });

        session.defaultSession.setPermissionRequestHandler((webContents, permission, callback) => {
          const allowedPermissions = ["notifications", "media"];
          callback(allowedPermissions.includes(permission));
        });

        session.defaultSession.cookies.on("changed", (event, cookie, cause, removed) => {
          if (
            !removed &&
            cookie.name === "token_v2" &&
            cookie.domain &&
            (cookie.domain.includes("notion.so") || cookie.domain.includes("notion.com"))
          ) {
            session.defaultSession.cookies.flushStore();

            setTimeout(() => {
              if (mainWindow && !mainWindow.isDestroyed()) {
                const currentUrl = mainWindow.webContents.getURL();
                if (currentUrl.includes("/login")) {
                  mainWindow.loadURL("https://www.notion.so");
                }
              }
            }, 300);
          }
        });

        const iconPath = path.join(__dirname, "notion.png");

        mainWindow = new BrowserWindow({
          width: 1280,
          height: 850,
          minWidth: 480,
          minHeight: 360,
          title: "Notion",
          icon: iconPath,
          autoHideMenuBar: true,
          backgroundColor: "#191919",
          webPreferences: {
            nodeIntegration: false,
            contextIsolation: false,
            sandbox: false,
            spellcheck: true,
          },
        });

        mainWindow.webContents.setWindowOpenHandler((details) => {
          const { url, frameName } = details;

          if (url && url.startsWith("notion://")) {
            mainWindow.loadURL(normalizeUrl(url));
            return { action: "deny" };
          }

          if (
            !url ||
            url === "" ||
            url === "about:blank" ||
            frameName === "googlePopup" ||
            isInternalOrAuthUrl(url)
          ) {
            return {
              action: "allow",
              overrideBrowserWindowOptions: {
                autoHideMenuBar: true,
                backgroundColor: "#191919",
              },
            };
          }

          shell.openExternal(url);
          return { action: "deny" };
        });

        mainWindow.webContents.on("did-create-window", (childWindow) => {
          childWindow.webContents.setUserAgent(USER_AGENT);

          childWindow.on("closed", () => {
            if (mainWindow && !mainWindow.isDestroyed()) {
              setTimeout(() => {
                if (mainWindow && !mainWindow.isDestroyed()) {
                  const currentUrl = mainWindow.webContents.getURL();
                  if (currentUrl.includes("/login")) {
                    mainWindow.loadURL("https://www.notion.so");
                  }
                }
              }, 500);
            }
          });

          childWindow.webContents.on("will-navigate", (event, url) => {
            if (url.startsWith("notion://")) {
              event.preventDefault();
              mainWindow.loadURL(normalizeUrl(url));
              childWindow.close();
              return;
            }

            if (!isInternalOrAuthUrl(url)) {
              event.preventDefault();
              shell.openExternal(url);
            }
          });

          childWindow.webContents.setWindowOpenHandler((details) => {
            const { url } = details;
            if (!url || url === "" || url === "about:blank" || isInternalOrAuthUrl(url)) {
              return { action: "allow" };
            }

            shell.openExternal(url);
            return { action: "deny" };
          });
        });

        mainWindow.webContents.on("will-navigate", (event, url) => {
          if (url.startsWith("notion://")) {
            event.preventDefault();
            mainWindow.loadURL(normalizeUrl(url));
            return;
          }

          if (!isInternalOrAuthUrl(url)) {
            event.preventDefault();
            shell.openExternal(url);
          }
        });

        const targetArg = process.argv.find(arg =>
          arg.startsWith("http://") ||
          arg.startsWith("https://") ||
          arg.startsWith("notion://")
        );
        mainWindow.loadURL(normalizeUrl(targetArg));

        mainWindow.on("page-title-updated", (event, title) => {
          if (!title.includes("Notion")) {
            mainWindow.setTitle(title + " - Notion");
          }
        });
      });

      app.on("before-quit", async () => {
        if (session.defaultSession) {
          try {
            await session.defaultSession.cookies.flushStore();
          } catch (e) {}
        }
      });

      app.on("window-all-closed", () => {
        if (process.platform !== "darwin") {
          app.quit();
        }
      });
    }
  '';

  notionAppDir = pkgs.runCommand "notion-desktop-files" { } ''
    mkdir -p $out
    cp ${packageJson} $out/package.json
    cp ${mainJs} $out/main.js
    cp ${wikipediaNotionSvg} $out/notion.svg
    cp ${notionPng} $out/notion.png
  '';

  notion-app = pkgs.writeShellScriptBin "notion-app" ''
    exec ${pkgs.electron}/bin/electron ${notionAppDir} "$@"
  '';
in
{
  home.packages = [
    notion-app
  ];

  xdg.desktopEntries.notion = {
    name = "Notion";
    genericName = "Notes & Workspace";
    comment = "Connected workspace for notes, docs, and projects";
    exec = "notion-app %U";
    icon = "${notionPng}";
    terminal = false;
    categories = [ "Office" "Utility" "TextEditor" ];
    mimeType = [ "x-scheme-handler/notion" ];
    settings = {
      StartupWMClass = "notion-app";
    };
  };

  xdg.dataFile."icons/hicolor/scalable/apps/notion.svg".source = wikipediaNotionSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/notion.png".source = notionPng;
  home.file.".local/share/pixmaps/notion.png".source = notionPng;
  home.file.".local/share/pixmaps/notion.svg".source = wikipediaNotionSvg;
}
