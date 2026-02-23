{ pkgs, ... }:

{
  services.flatpak = {
    enable = true;
    
    # Add the Flathub repository
    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];

    # List of packages to install automatically
    packages = [
      "com.tencent.WeChat"
      "io.github.mimbrero.WhatsAppDesktop"
      "com.ultimaker.cura"                     # <--- ADD THIS LINE
    ];

    # Optional: Update flatpaks automatically on system activation
    update.onActivation = true;
  };
}
