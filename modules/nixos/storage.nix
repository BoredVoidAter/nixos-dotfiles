{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" "exfat" ];

  environment.systemPackages = with pkgs; [
    gnome-disk-utility # "Disks" GUI - click SD card -> "Format Disk" (FAT / exFAT)
    gparted            # Partition manager for advanced resizing/partitioning
    dosfstools         # mkfs.fat / FAT32 support
    exfatprogs         # mkfs.exfat / modern exFAT support
  ];
}
