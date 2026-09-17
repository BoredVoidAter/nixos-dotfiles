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
    powerOnBoot = false;
    settings = {
      General = {
        Experimental = true;
      };
      Policy = {
        AutoEnable = "false";
      };
    };
  };

  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol # Often needed system-wide or per user, putting here for convenience if system audio
    bluez
    bluez-tools
  ];
}
