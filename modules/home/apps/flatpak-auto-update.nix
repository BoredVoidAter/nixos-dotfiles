{ config, pkgs, ... }:

{
  # Background flatpak update service - runs after login instead of blocking boot
  systemd.user.services.flatpak-auto-update = {
    unitConfig = {
      Description = "Auto-update Flatpak applications in background";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.flatpak}/bin/flatpak update --system --noninteractive -y";
      # Run with lower priority to not impact system responsiveness
      Nice = 19;
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
    };
    # Run 5 minutes after login to let the system settle
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "24h";
      Persistent = true;
      RandomizedDelaySec = "10min";
    };
  };
}