{ pkgs, ... }:

{
  services.flatpak = {
    enable = true;


    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];


    packages = [
      "com.tencent.WeChat"
      "io.github.mimbrero.WhatsAppDesktop"
      "com.ultimaker.cura"
      "org.jdownloader.JDownloader" # <--- ADD THIS LINE
    ];


    update.onActivation = true;
  };
}
