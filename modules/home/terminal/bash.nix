{ pkgs, ... }:

let

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


    TMP_FILE=$(mktemp)

    ${pkgs.yt-dlp}/bin/yt-dlp --flat-playlist --print "%(id)s|%(duration)s|%(title)s" "$URL" > "$TMP_FILE"

    while IFS='|' read -r id duration title; do

      duration=''${duration%.*}


      if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo "Skipping video with unknown duration: $title"
        continue
      fi


      if (( duration > MAX_SECONDS )); then
        echo "WARNING: '$title' is longer than 78 minutes! It will fail to burn on a standard CD."
      fi


      if (( CURRENT_TIME + duration > MAX_SECONDS )); then
        CURRENT_CD=$((CURRENT_CD + 1))
        CURRENT_TIME=0
        TRACK_NUM=1
        echo "----------------------------------------"
        echo "Limit reached. Moving to CD_$CURRENT_CD"
        echo "----------------------------------------"
      fi


      CURRENT_TIME=$((CURRENT_TIME + duration))


      mkdir -p "CD_$CURRENT_CD"


      TRACK_STR=$(printf "%02d" $TRACK_NUM)

      echo "Downloading to CD_$CURRENT_CD: [$TRACK_STR] $title ($duration sec)"


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


  yt-cd-list-script = pkgs.writeShellScriptBin "yt-cd-list" ''
    echo "Scanning for CD folders..."
    

    PARENT_DIR=$(basename "$PWD")
    

    for dir in CD_*/; do

      [ -d "$dir" ] || continue
      

      CD_NAME=''${dir%/}
      OUTPUT_FILE="$dir/TRACKLIST.txt"
      
      echo "Generating $OUTPUT_FILE..."
      

      > "$OUTPUT_FILE"
      echo "=== $PARENT_DIR / $CD_NAME TRACKLIST ===" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      

      SONG_LIST=""
      

      for file in "$dir"*.wav; do

        [ -e "$file" ] || continue
        

        filename=$(basename "$file")
        

        clean_name="''${filename%.*}"
        

        echo "$clean_name" >> "$OUTPUT_FILE"
        


        title_only=$(echo "$clean_name" | sed -E 's/^[0-9]+ - //')
        if [ -z "$SONG_LIST" ]; then
          SONG_LIST="'$title_only'"
        else
          SONG_LIST="$SONG_LIST, '$title_only'"
        fi
      done
      
      echo "" >> "$OUTPUT_FILE"
      echo "=== AI ALBUM COVER PROMPT ===" >> "$OUTPUT_FILE"
      echo "A highly detailed, maximalist, meme-heavy album cover design inspired by the themes, jokes, and vibes of these songs: $SONG_LIST. The artwork must feature an intricate, chaotic composition filled with surreal internet memes, dense details, and wild energy. Strict color palette: you must use ONLY solid black, solid white, and exactly ONE other vibrant color of your choosing. Absolutely no gradients, shading, or additional colors. Leave a small empty space at the top or bottom for typography to be added later. Crisp vector art style, clean edges, completely textless." >> "$OUTPUT_FILE"
      
    done
    
    echo "Done! Check the TRACKLIST.txt files inside each CD folder."
  '';

in
{

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

