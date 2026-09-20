{ pkgs, ... }:

{
  services.flatpak = {
    enable = true;


    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];


    packages = [
      "com.ultimaker.cura"
      "org.jdownloader.JDownloader"
      "com.valvesoftware.Steam"
    ];


    update.onActivation = true;
  };
}
