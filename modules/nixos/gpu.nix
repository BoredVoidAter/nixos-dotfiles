{ pkgs, config, ... }:

{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      ocl-icd
      intel-compute-runtime # Fixes DaVinci Resolve aborting on the iGPU
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Automatically creates the 'nvidia-offload' script
      };
      
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;    # Essential for Wayland/Hyprland display capture
    openFirewall = true;   # Opens ports 47984-48010 for Moonlight
  };

  environment.systemPackages = with pkgs; [
    steam-run
    cudatoolkit
  ];
}
