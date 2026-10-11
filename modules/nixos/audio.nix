{ pkgs, ... }:

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        JustWorksRepairing = "always";
        FastConnectable = "true";
        Privacy = "device";
      };
      Policy = {
        AutoEnable = "true";
        ReconnectAttempts = 7;
        ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
      };
    };
  };

  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol
    bluez
    bluez-tools
  ];
}
