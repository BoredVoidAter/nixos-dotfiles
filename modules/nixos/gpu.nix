{ pkgs, config, ... }:

{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      ocl-icd
      intel-compute-runtime # Add this! Fixes DaVinci Resolve aborting on the iGPU
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      # Change from sync to offload
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

  environment.systemPackages = with pkgs; [
    steam-run
    cudatoolkit
  ];
}
