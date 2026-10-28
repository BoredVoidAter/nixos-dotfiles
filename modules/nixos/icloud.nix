{ config, pkgs, lib, ... }:

let
  cfg = config.services.icloud-drive;
in
{
  options.services.icloud-drive = {
    enable = lib.mkEnableOption "iCloud Drive integration via rclone (uses main password + 2FA)";
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
    # Read-only mount (safer - rclone iCloud is experimental)
    readOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Mount read-only (rclone iCloud is experimental)";
    };
    # User to run the mount service as (should be your user for rclone config access)
    mountUser = lib.mkOption {
      type = lib.types.str;
      default = "boredvoidater";
      description = "User to run the mount service as (needs access to ~/.config/rclone/rclone.conf)";
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
        # Mount iCloud Drive (uses rclone config with cached trust token)
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
            echo "Mount failed. Run: icloud-config"
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
        # Interactive rclone config for iCloud (main password + 2FA)
        echo "Configuring iCloud remote 'icloud'..."
        echo "Use your MAIN Apple ID password (not app-specific) + 2FA code"
        ${pkgs.rclone}/bin/rclone config
      '')
    ];

    # Create mount point
    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0755 ${config.users.users.${config.services.icloud-drive.mountUser or "boredvoidater"}.name} ${config.users.users.${config.services.icloud-drive.mountUser or "boredvoidater"}.group} - -"
    ];

    # systemd service to mount iCloud Drive (runs as user to access rclone config)
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
        # Run as your user to access ~/.config/rclone/rclone.conf with cached trust token
        User = config.services.icloud-drive.mountUser or "boredvoidater";
      };
    };

    # Auto-start (optional, user can enable manually)
    systemd.services.icloud-drive.wantedBy = [ "multi-user.target" ];
  };
}