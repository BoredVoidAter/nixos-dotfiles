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
      "org.freedownloadmanager.Manager"
      "moe.karaokes.mugen"
    ];


    # Disable onActivation to prevent blocking boot (was taking ~65s)
    # Flatpaks will be installed/updated in background via flatpak-system-helper
    update.onActivation = false;
  };
}
