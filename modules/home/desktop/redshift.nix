{ pkgs, ... }:

{
  services.redshift = {
    enable = true;

    provider = "manual";
    latitude = 51.1657;
    longitude = 10.4515;

    temperature = {
      day = 6500;

      night = 1800;
    };

    settings = {
      redshift = {
        dawn-time = "06:00-07:00";

        dusk-time = "18:00-22:30";
      };
    };
  };


  systemd.user.services.redshift = {
    Service.ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
  };
}

