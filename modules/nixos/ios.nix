{ config, pkgs, ... }:

{
  # iOS/iPhone USB support
  services.usbmuxd = {
    enable = true;
  };

  # GVFS for GUI file manager integration (Thunar, Nautilus, etc.)
  # gvfs with afc backend for mounting iOS devices in file managers
  services.gvfs.enable = true;

  # Packages needed for iPhone/iOS device access
  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
    usbmuxd
    libplist
    ideviceinstaller
    idevicerestore
    libimobiledevice-glue
    gvfs
  ];
}