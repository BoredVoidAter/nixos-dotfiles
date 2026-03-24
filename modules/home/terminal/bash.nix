{ pkgs, ... }:

let
  # The smart YouTube-to-CD Playlist Splitter script
  yt-cd-script = pkgs.writeShellScriptBin "yt-cd" ''
    if [ -z "$1" ]; then
      echo "Usage: yt-cd <youtube-playlist-url>"
      exit 1
    fi

    URL=$1
    MAX_SECONDS=4680 # 78 minutes (safe limit for 80min CDs)
    CURRENT_CD=1
    CURRENT_TIME=0
    TRACK_NUM=1

    echo "Fetching playlist info (this might take a few seconds)..."
    
    # Use a temporary file to hold the playlist metadata (id, duration, title)
    TMP_FILE=$(mktemp)
    
    ${pkgs.yt-dlp}/bin/yt-dlp --flat-playlist --print "%(id)s|%(duration)s|%(title)s" "$URL" > "$TMP_FILE"

    while IFS='|' read -r id duration title; do
      # Clean duration (remove decimals if any)
      duration=''${duration%.*}
      
      # If duration is missing/invalid (like a live stream), skip it
      if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo "Skipping video with unknown duration: $title"
        continue
      fi

      # Warn if a single track is longer than a whole CD
      if (( duration > MAX_SECONDS )); then
        echo "WARNING: '$title' is longer than 78 minutes! It will fail to burn on a standard CD."
      fi

      # Check if adding this track exceeds the 78 minute limit
      if (( CURRENT_TIME + duration > MAX_SECONDS )); then
        CURRENT_CD=$((CURRENT_CD + 1))
        CURRENT_TIME=0
        TRACK_NUM=1
        echo "----------------------------------------"
        echo "Limit reached. Moving to CD_$CURRENT_CD"
        echo "----------------------------------------"
      fi

      # Add to current CD time
      CURRENT_TIME=$((CURRENT_TIME + duration))

      # Create the folder for the current CD
      mkdir -p "CD_$CURRENT_CD"
      
      # Format track number to always be 2 digits (01, 02, 03...)
      TRACK_STR=$(printf "%02d" $TRACK_NUM)
      
      echo "Downloading to CD_$CURRENT_CD: [$TRACK_STR] $title ($duration sec)"
      
      # Download the individual track straight into the CD folder as WAV
      ${pkgs.yt-dlp}/bin/yt-dlp -f 'ba' -x --audio-format wav \
             --postprocessor-args '-ar 44100' \
             -o "CD_$CURRENT_CD/$TRACK_STR - %(title)s.%(ext)s" \
             "https://youtube.com/watch?v=$id"

      TRACK_NUM=$((TRACK_NUM + 1))

    done < "$TMP_FILE"

    rm "$TMP_FILE"
    echo "Done! Your folders (CD_1, CD_2...) are ready to be dragged into Brasero."
  '';

in
{
  # Add our custom script to the user's installed packages
  home.packages = [ yt-cd-script ];

  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      n = "nvim";
      # Since we installed Unity via Nix, we can usually just run unityhub
      unity = "nvidia-offload unityhub";         
      aw = "firefox http://localhost:5600";
      ym = "yt";
      sops-edit = "nix shell nixpkgs#sops -c sops ~/nixos-dotfiles/secrets/secrets.yaml";
    };
  };
}
