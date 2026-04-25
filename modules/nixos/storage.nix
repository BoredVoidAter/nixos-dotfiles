{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/mnt/Games" = {
    device = "/dev/disk/by-uuid/08437199003569B8";
    fsType = "ntfs3";
    options = [ "uid=1000" "gid=1000" "nofail" ];
  };
}
