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
    ];

    # Optional: Update flatpaks automatically on system activation
    update.onActivation = true;
  };
}
