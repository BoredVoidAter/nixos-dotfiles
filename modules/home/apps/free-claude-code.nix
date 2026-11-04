{ pkgs, config, ... }:

let
  claude-free = pkgs.writeShellScriptBin "claude-free" ''
    CLAUDE_FREE_DIR="$HOME/.local/share/free-claude-code"
    mkdir -p "$CLAUDE_FREE_DIR"
    
    # Isolate uv environment for free-claude-code
    export UV_INSTALL_DIR="$CLAUDE_FREE_DIR/.uv"
    export UV_TOOL_DIR="$CLAUDE_FREE_DIR/.uv-tools"
    export UV_TOOL_BIN_DIR="$CLAUDE_FREE_DIR/.uv-bin"
    UV_BIN="$UV_INSTALL_DIR/uv"
    
    # Isolate npm environment so we can install the official claude CLI locally
    export NPM_CONFIG_PREFIX="$CLAUDE_FREE_DIR/.npm-global"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
    
    # Clean up old git-based installation if present
    if [ -d "$CLAUDE_FREE_DIR/.git" ]; then
      echo "Migrating from old git-based installation to uv package..."
      rm -rf "$CLAUDE_FREE_DIR"/* "$CLAUDE_FREE_DIR"/.* 2>/dev/null || true
      mkdir -p "$CLAUDE_FREE_DIR"
    fi
    
    if [ ! -x "$UV_BIN" ]; then
        echo "Installing standalone uv..."
        ${pkgs.curl}/bin/curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 UV_INSTALL_DIR="$UV_INSTALL_DIR" sh
    fi
    
    # Only update if no proxy is currently running to avoid breaking active instances
    if ! ${pkgs.procps}/bin/pgrep -f "fcc-server" > /dev/null; then
        "$UV_BIN" self update --quiet 2>/dev/null || true
        echo "Installing / Updating free-claude-code wrapper..."
        "$UV_BIN" tool install --force free-claude-code --quiet
    fi
    
    # Ensure the official Claude CLI is installed so fcc-claude can wrap it
    if ! command -v claude >/dev/null 2>&1; then
        echo "Installing official Claude Code CLI..."
        ${pkgs.nodejs}/bin/npm install -g @anthropic-ai/claude-code --quiet
    fi
    
    # Start proxy if it isn't already running
    if ! ${pkgs.procps}/bin/pgrep -f "fcc-server" > /dev/null; then
        echo "Starting fcc-server proxy..."
        "$UV_TOOL_BIN_DIR/fcc-server" > "$CLAUDE_FREE_DIR/proxy.log" 2>&1 &
        
        # Give the server a moment to bind
        sleep 2
        
        if ! ${pkgs.procps}/bin/pgrep -f "fcc-server" > /dev/null; then
          echo "Error: fcc-server crashed! Check proxy.log in $CLAUDE_FREE_DIR for details."
          cat "$CLAUDE_FREE_DIR/proxy.log"
          exit 1
        fi
    else
        echo "fcc-server is already running. Connecting to existing instance..."
    fi
    
    # On first run, open the Admin UI so the user can configure their API keys
    # We skip this if SOPS is managing the ~/.fcc/.env file (it will be a symlink)
    if [ ! -f "$CLAUDE_FREE_DIR/.configured" ] && [ ! -L "$HOME/.fcc/.env" ]; then
      echo "--------------------------------------------------------"
      echo "Opening the local Admin UI in your browser..."
      echo "Please configure your API keys (e.g. OpenRouter, etc.)."
      echo "--------------------------------------------------------"
      
      # Try to extract the admin URL from the log, default to 8082 if not found
      ADMIN_URL=$(${pkgs.gnugrep}/bin/grep -oE "http://(127\.0\.0\.1|localhost):[0-9]+/admin" "$CLAUDE_FREE_DIR/proxy.log" | head -n 1)
      if [ -z "$ADMIN_URL" ]; then
         ADMIN_URL="http://127.0.0.1:8082/admin"
      fi
      
      ${pkgs.xdg-utils}/bin/xdg-open "$ADMIN_URL" || true
      read -p "Once you click 'Apply' in the browser, press [Enter] here to launch Claude Code..."
      touch "$CLAUDE_FREE_DIR/.configured"
    fi
    
    echo "Launching Claude Code via fcc-claude..."
    "$UV_TOOL_BIN_DIR/fcc-claude" "$@"
    
    # Cleanup proxy on exit only if this is the last active instance
    if ! ${pkgs.procps}/bin/pgrep -f "fcc-claude" > /dev/null; then
        ${pkgs.procps}/bin/pkill -f "fcc-server" 2>/dev/null || true
    fi
  '';
in
{
  home.packages = [
    claude-free
    pkgs.nodejs
    pkgs.xdg-utils
    pkgs.gnugrep
    pkgs.procps
  ];

  # This tells sops-nix to decrypt the `fcc_env` key from your secrets.yaml 
  # and place it securely at ~/.fcc/.env
  sops.secrets."fcc_env" = {
    path = "${config.home.homeDirectory}/.fcc/.env";
  };
}
