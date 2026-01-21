{ pkgs, ... }:

{
  # -- Audio --
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # -- Bluetooth --
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
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
