{ pkgs, config, lib, ... }:

{
  # Dynamically pull the latest Betterfox and apply it to any default profiles 
  # This allows Nix to enhance the browser without strictly wiping profile history!
  home.activation.betterfox = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for dir in ~/.mozilla/firefox/*.default*; do
      if [ -d "$dir" ]; then
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -sL https://raw.githubusercontent.com/yokoffing/Betterfox/main/user.js -o "$dir/user.js"
      fi
    done
  '';

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.keepassxc ];
    # Removing `profiles.default` stops Home Manager from forcing a fresh profile.
    # Firefox will now fall back to your original profile with all your history intact,
    # and Firefox Account Sync will handle downloading your preferred extensions!
  };
}
