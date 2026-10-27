{ pkgs, ... }:

let
  claude-free = pkgs.writeShellScriptBin "claude-free" ''
    CLAUDE_FREE_DIR="$HOME/.local/share/free-claude-code"
    PORT=8082
    
    if ! command -v uv >/dev/null 2>&1; then
        echo "Error: 'uv' is not installed."
        exit 1
    fi
    
    if [ ! -d "$CLAUDE_FREE_DIR" ]; then
      echo "Installing free-claude-code proxy..."
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/Alishahryar1/free-claude-code.git "$CLAUDE_FREE_DIR"
    fi
    
    cd "$CLAUDE_FREE_DIR"
    ${pkgs.git}/bin/git pull origin main --quiet
    
    if [ ! -f .env ]; then
      echo "First run: Setting up example .env in $CLAUDE_FREE_DIR"
      cp .env.example .env 2>/dev/null || touch .env
      echo "NVIDIA_NIM_API_KEY=nvapi-your-key-here" >> .env
      echo "MODEL=nvidia_nim/moonshotai/kimi-k2-instruct" >> .env
      echo "ANTHROPIC_AUTH_TOKEN=freecc" >> .env
      echo "--------------------------------------------------------"
      echo "Please edit $CLAUDE_FREE_DIR/.env with your API keys!"
      echo "Get a free NVIDIA NIM key from build.nvidia.com"
      echo "Then run 'claude-free' again."
      exit 1
    fi
    
    echo "Syncing dependencies via uv..."
    ${pkgs.uv}/bin/uv python install 3.14 --quiet 2>/dev/null || true
    ${pkgs.uv}/bin/uv sync --quiet
    
    echo "Starting local proxy on port $PORT..."
    ${pkgs.uv}/bin/uv run uvicorn server:app --host 127.0.0.1 --port "$PORT" > proxy.log 2>&1 &
    PROXY_PID=$!
    
    # Wait for the proxy to become available
    for i in {1..30}; do
      if ${pkgs.curl}/bin/curl -s -m 1 "http://127.0.0.1:$PORT/v1/models" -H "x-api-key: freecc" >/dev/null 2>&1; then
        break
      fi
      sleep 0.5
    done
    
    echo "Launching Claude Code..."
    export ANTHROPIC_BASE_URL="http://127.0.0.1:$PORT"
    export ANTHROPIC_AUTH_TOKEN="freecc"
    export ANTHROPIC_API_KEY="freecc"
    
    ${pkgs.nodejs}/bin/npx -y @anthropic-ai/claude-code@latest "$@"
    
    # Cleanup proxy on exit
    kill $PROXY_PID
  '';
in
{
  home.packages = [
    claude-free
    pkgs.uv
    pkgs.nodejs
  ];
}
