{ config, lib, pkgs, neohabit-src, ... }:

with lib;
let
  cfg = config.services.neohabit;

  # Build the Backend from our injected GitHub source
  backendPkg = pkgs.buildGoModule {
    pname = "neohabit-backend";
    version = "1.1.0-git";
    src = "${neohabit-src}/backend";

    vendorHash = "sha256-7PGwxcWxcNaqoIVqHcmNb6Qt6WeYRCwAcAfz80V+TMg=";

    subPackages =[ "core/cmd" ];

    postInstall = ''
      mv $out/bin/cmd $out/bin/neohabit-backend
      mkdir -p $out/share
      cp core/config/config.yaml $out/share/config.yaml
    '';
  };

  # Build the Frontend from our injected GitHub source
  frontendPkg = pkgs.buildNpmPackage {
    pname = "neohabit-frontend";
    version = "1.1.0-git";
    src = "${neohabit-src}/frontend";

    npmDepsHash = "sha256-dEqbtkk9B9vbGRRy8GtdhNqrOSLM6dLoZ4DUqDFDaPQ=";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/neohabit
      cp -r dist/* $out/share/neohabit/
      runHook postInstall
    '';
  };

  # Dynamically generate the runtime config
  runtimeConfig = pkgs.writeText "runtime-config.js" ''
    window.APP_CONFIG = {
      API_URL: '${cfg.apiUrl}',
      DISABLE_SIGNUP: ${if cfg.disableSignup then "true" else "false"},
      STRICT_USER_FIELDS: ${if cfg.strictUserFields then "true" else "false"},
      REQUIRE_EMAIL: ${if cfg.requireEmail then "true" else "false"},
      DEMO: ${if cfg.demo then "true" else "false"},
    };
  '';

in {
  # The NixOS Options
  options.services.neohabit = {
    enable = mkEnableOption "Neohabit";
    domain = mkOption { type = types.str; default = "localhost"; };
    backendPort = mkOption { type = types.port; default = 9000; };
    apiUrl = mkOption { type = types.str; default = "/api/"; };
    environmentFile = mkOption { type = types.path; };

    disableSignup = mkOption { type = types.bool; default = false; };
    strictUserFields = mkOption { type = types.bool; default = false; };
    requireEmail = mkOption { type = types.bool; default = false; };
    demo = mkOption { type = types.bool; default = false; };
  };

  # The System Configuration (Systemd, Postgres, Nginx)
  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "neohabit" ];
      ensureUsers =[{
        name = "neohabit";
        ensureDBOwnership = true;
      }];
    };

    systemd.services.neohabit-backend = {
      description = "Neohabit Backend";
      wantedBy = [ "multi-user.target" ];
      after =[ "network.target" "postgresql.service" ];
      requires = [ "postgresql.service" ];
      environment = {
        PG_DSN = "postgres:///neohabit?host=/run/postgresql";
        ADDRESS = "127.0.0.1:${toString cfg.backendPort}";
        FRONTEND_URL = "http://${cfg.domain}";
      };
      serviceConfig = {
        ExecStart = "${backendPkg}/bin/neohabit-backend -config ${backendPkg}/share/config.yaml";
        EnvironmentFile = cfg.environmentFile;
        Restart = "on-failure";
        User = "neohabit";
        DynamicUser = true;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.domain} = {
        locations."/" = {
          root = "${frontendPkg}/share/neohabit";
          tryFiles = "$uri $uri/ /index.html";
        };
        locations."= /runtime-config.js" = {
          alias = "${runtimeConfig}";
        };
        locations."/api/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.backendPort}/";
        };
      };
    };
  };
}
