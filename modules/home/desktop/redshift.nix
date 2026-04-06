{ pkgs, ... }:

{
  services.redshift = {
    enable = true;
    
    provider = "manual";
    latitude = 51.1657; 
    longitude = 10.4515;

    temperature = {
      day = 6500;   
      # Dropping this from 3000 to 1800 creates a deep red tint
      night = 1800; 
    };

    settings = {
      redshift = {
        dawn-time = "06:00-07:00";
        # Starts the fade at 6:00 PM and finishes exactly at 10:30 PM
        dusk-time = "18:00-22:30"; 
      };
    };
  };

  # Forces a 5-second delay on boot so Qtile/X11 is fully ready
  systemd.user.services.redshift = {
    Service.ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
  };
}

