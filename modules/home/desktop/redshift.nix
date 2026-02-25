{ pkgs, ... }:

{
  services.redshift = {
    enable = true;
    
    # We use a manual provider to satisfy the configuration requirements
    provider = "manual";
    latitude = 51.1657; # Approx center of Germany
    longitude = 10.4515;

    temperature = {
      day = 6500;   # Normal daylight temperature (Cool)
      night = 3500; # Blue light filtered temperature (Warm/Orange)
    };

    # Override the sun-based calculation to use strict time windows
    settings = {
      redshift = {
        # Gradually fades back to normal between 06:00 and 07:00
        dawn-time = "06:00-07:00";
        # Gradually applies the blue light filter between 18:00 and 18:30
        dusk-time = "18:00-18:30"; 
      };
    };
  };
}
