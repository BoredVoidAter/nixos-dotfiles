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
      ${pkgs.yt-dlp}/bin/yt-dlp -f 'ba/best' -x --audio-format wav \
             --postprocessor-args "ffmpeg:-ar 44100" \
             --extractor-args "youtube:player_client=android" \
             -o "CD_$CURRENT_CD/$TRACK_STR - %(title)s.%(ext)s" \
             "https://youtube.com/watch?v=$id"

      TRACK_NUM=$((TRACK_NUM + 1))

    done < "$TMP_FILE"

    rm "$TMP_FILE"
    echo "Done! Your folders (CD_1, CD_2...) are ready to be dragged into Brasero or K3b."
  '';

  # The Tracklist and AI Prompt Generator
  yt-cd-list-script = pkgs.writeShellScriptBin "yt-cd-list" ''
    echo "Scanning for CD folders..."
    
    # Loop through any directory that starts with CD_
    for dir in CD_*/; do
      # Skip if no directories match
      [ -d "$dir" ] || continue
      
      # Remove trailing slash for the CD name
      CD_NAME=''${dir%/}
      OUTPUT_FILE="$dir/TRACKLIST.txt"
      
      echo "Generating $OUTPUT_FILE..."
      
      # Clear or create the output file
      > "$OUTPUT_FILE"
      echo "=== $CD_NAME TRACKLIST ===" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      
      # We will store the song names in a variable for the AI prompt
      SONG_LIST=""
      
      # Read all wav files in the directory
      for file in "$dir"*.wav; do
        # Skip if no wav files found
        [ -e "$file" ] || continue
        
        # Get just the filename, not the path
        filename=$(basename "$file")
        
        # Strip the .wav extension using bash parameter expansion
        clean_name="''${filename%.*}"
        
        # Append to the tracklist file
        echo "$clean_name" >> "$OUTPUT_FILE"
        
        # Add to the song list string for the AI prompt (comma separated)
        # We remove the leading numbers (e.g. "01 - ") for the prompt so the AI just gets the titles
        title_only=$(echo "$clean_name" | sed -E 's/^[0-9]+ - //')
        if [ -z "$SONG_LIST" ]; then
          SONG_LIST="'$title_only'"
        else
          SONG_LIST="$SONG_LIST, '$title_only'"
        fi
      done
      
      echo "" >> "$OUTPUT_FILE"
      echo "=== AI ALBUM COVER PROMPT ===" >> "$OUTPUT_FILE"
      echo "A minimalist, conceptual album cover design inspired by the themes of these songs: $SONG_LIST. The artwork must be strictly high-contrast black and white, using striking silhouettes, clean lines, and negative space to visually represent the mood of the music. The only color allowed in the entire image is a bold [INSERT ONE COLOR HERE], used sparingly as a dramatic accent to highlight the central focal point. The composition should leave empty negative space at the top or bottom for typography to be added later. Professional graphic design, flat vector art style, clean edges, completely textless." >> "$OUTPUT_FILE"
      
    done
    
    echo "Done! Check the TRACKLIST.txt files inside each CD folder."
  '';

in
{
  # Add both scripts to the user's installed packages
  home.packages = [ 
    yt-cd-script 
    yt-cd-list-script 
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles";
      n = "nvim";
      unity = "nvidia-offload unityhub";
      aw = "firefox http://localhost:5600";
      ym = "yt";
      yl = "yt-cd-list"; # <-- New alias to run the tracklist generator
      sops-edit = "nix shell nixpkgs#sops -c sops ~/nixos-dotfiles/secrets/secrets.yaml";
    };
  };
}

