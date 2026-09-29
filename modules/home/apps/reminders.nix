{ config, pkgs, lib, ... }:

let
  cfg = config.boredvoidater;
in
{
  options.boredvoidater.appleId = lib.mkOption {
    type = lib.types.str;
    default = "boredvoideater@proton.me";
    description = "Apple ID email for iCloud CalDAV sync.";
  };

  config = {
    home.packages = with pkgs; [
      vdirsyncer
      todoman
    ];

    sops.secrets.icloud_app_password = { };

    xdg.configFile."vdirsyncer/config".text = ''
      [general]
      status_path = "~/.local/share/vdirsyncer/status/"

      [pair reminders]
      a = "reminders_local"
      b = "reminders_icloud"
      collections = ["from a", "from b"]

      [storage reminders_local]
      type = "filesystem"
      path = "~/.local/share/calendars/reminders/"
      fileext = ".ics"

      [storage reminders_icloud]
      type = "caldav"
      url = "https://caldav.icloud.com/"
      username = "${cfg.appleId}"
      password.fetch = ["command", "cat", "${config.sops.secrets.icloud_app_password.path}"]
      read_only = false
    '';

    xdg.configFile."todoman/config.py".text = ''
      path = "~/.local/share/calendars/reminders/*"
      date_format = "%Y-%m-%d"
      time_format = "%H:%M"
      default_due = 24
    '';

    systemd.user.services.vdirsyncer-sync = {
      Unit = {
        Description = "Synchronize iCloud Reminders with vdirsyncer";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
      };
    };

    systemd.user.timers.vdirsyncer-sync = {
      Unit = {
        Description = "Periodic synchronization of iCloud Reminders";
      };
      Timer = {
        OnBootSec = "2m";
        OnUnitActiveSec = "15m";
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
