{ config, pkgs, lib, ... }:

let
  cfg = config.services.icloud-drive;
in
{
  options.services.icloud-drive = {
    enable = lib.mkEnableOption "iCloud Drive integration via rclone";
    appleId = lib.mkOption {
      type = lib.types.str;
      description = "Apple ID email";
      default = "";
    };
    mountPoint = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/icloud-drive";
      description = "Mount point for iCloud Drive";
    };
    # App-specific password (generate at appleid.apple.com)
    # Store in SOPS (decrypted to /run/secrets/icloud_app_password) or pass via file
    appPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = "/run/secrets/icloud_app_password";
      description = "File containing app-specific password (one line). Defaults to SOPS secret path.";
    };
    # Read-only mount (safer)
    readOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Mount read-only (rclone iCloud is experimental)";
    };
    mountUser = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run the mount service as";
    };
  };

  config = lib.mkIf cfg.enable {
    # rclone with iCloud support
    environment.systemPackages = with pkgs; [
      rclone
      fuse3
      # User-friendly mount scripts
      (writeShellScriptBin "icloud-mount" ''
        #!/bin/sh
        # Mount iCloud Drive interactively (prompts for password if not in config)
        MOUNT_POINT="${cfg.mountPoint}"
        mkdir -p "$MOUNT_POINT"
        if mountpoint -q "$MOUNT_POINT"; then
          echo "Already mounted at $MOUNT_POINT"
        else
          echo "Mounting iCloud Drive at $MOUNT_POINT..."
          ${pkgs.rclone}/bin/rclone mount icloud: "$MOUNT_POINT" \
            --vfs-cache-mode full \
            --vfs-cache-max-size 1G \
            --daemon
          sleep 2
          if mountpoint -q "$MOUNT_POINT"; then
            echo "Mounted successfully!"
            echo "Access in Thunar: $MOUNT_POINT"
          else
            echo "Mount failed. Check: rclone config icloud:"
          fi
        fi
      '')
      (writeShellScriptBin "icloud-unmount" ''
        #!/bin/sh
        MOUNT_POINT="${cfg.mountPoint}"
        ${pkgs.rclone}/bin/rclone unmount "$MOUNT_POINT"
        echo "Unmounted iCloud Drive"
      '')
      (writeShellScriptBin "icloud-config" ''
        #!/bin/sh
        # Interactive rclone config for iCloud
        ${pkgs.rclone}/bin/rclone config
      '')
    ];

    # Create mount point
    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0755 ${config.users.users.${config.services.icloud-drive.mountUser or "root"}.name} ${config.users.users.${config.services.icloud-drive.mountUser or "root"}.group} - -"
    ];

    # systemd service to mount iCloud Drive
    systemd.services.icloud-drive = {
      description = "iCloud Drive FUSE mount via rclone";
      documentation = [ "https://rclone.org/icloud/" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "notify";
        ExecStartPre = "/bin/mkdir -p ${cfg.mountPoint}";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount icloud: ${cfg.mountPoint} \
            --vfs-cache-mode full \
            --vfs-cache-max-size 1G \
            --vfs-cache-max-age 24h \
            --vfs-read-chunk-size 16M \
            --vfs-read-chunk-size-limit 256M \
            --dir-cache-time 24h \
            --poll-interval 30s \
            --umask 022 \
            ${lib.optionalString cfg.readOnly "--read-only"} \
            --daemon \
            --log-level INFO
        '';
        ExecStop = "${pkgs.rclone}/bin/rclone unmount ${cfg.mountPoint}";
        Restart = "on-failure";
        RestartSec = 10;
        # Run as user for better permissions
        User = config.services.icloud-drive.mountUser or "root";
      };
      # Need the app password
      environment = {
        RCLONE_CONFIG_ICLOUD_PASS = "command:cat ${cfg.appPasswordFile}";
      };
    };

    # Auto-start (optional, user can enable manually)
    systemd.services.icloud-drive.wantedBy = [ "multi-user.target" ];

    # Add to Thunar bookmarks (user-specific, via home-manager)
    # This would be better in home.nix but we can provide the path
  };
}