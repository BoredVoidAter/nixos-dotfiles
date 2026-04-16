{ config, pkgs, lib, ... }:

let
  # Replace this with the actual domain you plan to route to your machine
  domain = "mcp.yourdomain.com";

  # Use the Node.js 22 npx binary directly
  npx = "${pkgs.nodejs_22}/bin/npx";

  # Helper function to create a Supergateway systemd service
  mkMcpService = { name, port, stdioCmd }: {
    description = "MCP Server: ${name}";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      # Supergateway wraps the stdio command and exposes it via SSE on the given port
      ExecStart = "${npx} -y supercorp-ai/supergateway@latest --port ${toString port} --stdio \"${stdioCmd}\"";
      Restart = "always";
      RestartSec = "5s";
      User = "boredvoidater";
      WorkingDirectory = config.users.users.boredvoidater.home;
      Environment = [
        "PATH=${lib.makeBinPath [ pkgs.nodejs_22 pkgs.git pkgs.nix pkgs.repomix ]}"
      ];
    };
  };

in
{
  # Ensure necessary packages are available system-wide
  environment.systemPackages = with pkgs; [
    nodejs_22
    repomix
    apacheHttpd # Required if you ever need to manually run htpasswd locally
  ];

  # 1. Define the SOPS secret for Nginx Basic Authentication
  sops.secrets."mcp_htpasswd" = {
    # Nginx needs permission to read this file to authenticate incoming requests
    owner = config.services.nginx.user;
    group = config.services.nginx.group;
    mode = "0400";
  };

  # 2. Define the Systemd services for the MCP servers
  systemd.services = {
    
    # Repomix MCP Service (Port 8001)
    mcp-repomix = mkMcpService {
      name = "Repomix";
      port = 8001;
      stdioCmd = "${npx} -y repomix mcp";
    };

    # Filesystem MCP Service (Port 8002)
    # Restricts the AI's filesystem access to just your NixOS config and dotfiles
    mcp-filesystem = mkMcpService {
      name = "Filesystem";
      port = 8002;
      stdioCmd = "${npx} -y @modelcontextprotocol/server-filesystem /etc/nixos /home/boredvoidater/nixos-dotfiles";
    };

  };

  # 3. Secure Reverse Proxy (Nginx)
  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      # Use Let's Encrypt for public domains (set enableACME = false if using Tailscale certs)
      forceSSL = true; 
      enableACME = true;
      
      # Read the Basic Auth credentials directly from the decrypted SOPS file
      basicAuthFile = config.sops.secrets."mcp_htpasswd".path;

      locations = {
        # Route /repomix to port 8001
        "/repomix/" = {
          proxyPass = "http://127.0.0.1:8001/";
          proxyWebsockets = true; # Required for SSE connections
          extraConfig = ''
            proxy_set_header Connection '';
            proxy_http_version 1.1;
            chunked_transfer_encoding off;
            proxy_buffering off;
            proxy_cache off;
            proxy_read_timeout 24h;
          '';
        };

        # Route /filesystem to port 8002
        "/filesystem/" = {
          proxyPass = "http://127.0.0.1:8002/";
          proxyWebsockets = true; # Required for SSE connections
          extraConfig = ''
            proxy_set_header Connection '';
            proxy_http_version 1.1;
            chunked_transfer_encoding off;
            proxy_buffering off;
            proxy_cache off;
            proxy_read_timeout 24h;
          '';
        };
      };
    };
  };
}
