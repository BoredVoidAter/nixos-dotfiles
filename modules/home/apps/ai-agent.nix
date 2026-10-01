{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.aiAgents;

  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    requests
    beautifulsoup4
    pyyaml
    (ps.ddgs or ps.duckduckgo-search)
  ]);

  # Model Context Protocol stdio server providing web search, game search, and page fetching
  mcpSearchServer = pkgs.writeScriptBin "agent-mcp-search" ''
    #!${pythonEnv}/bin/python3
    import json
    import re
    import sys
    import urllib.parse
    import urllib.request
    from bs4 import BeautifulSoup

    def run_duckduckgo_search(query: str, max_results: int = 5):
        try:
            from duckduckgo_search import DDGS
            with DDGS() as ddgs:
                results = list(ddgs.text(query, max_results=max_results))
                return [
                    {"title": r.get("title", ""), "href": r.get("href", ""), "body": r.get("body", "")}
                    for r in results
                ]
        except Exception:
            pass

        try:
            headers = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0"}
            data = urllib.parse.urlencode({"q": query}).encode("utf-8")
            req = urllib.request.Request("https://html.duckduckgo.com/html/", data=data, headers=headers)
            with urllib.request.urlopen(req, timeout=10) as resp:
                soup = BeautifulSoup(resp.read().decode("utf-8", errors="ignore"), "html.parser")
            items = []
            for result in soup.select(".result")[:max_results]:
                t = result.select_one(".result__title")
                s = result.select_one(".result__snippet")
                if t:
                    a = t.select_one("a")
                    href = a.get("href", "") if a else ""
                    if "uddg=" in href:
                        href = urllib.parse.unquote(href.split("uddg=")[1].split("&")[0])
                    items.append({
                        "title": t.get_text(strip=True),
                        "href": href,
                        "body": s.get_text(strip=True) if s else ""
                    })
            return items
        except Exception as e:
            return [{"error": f"Search failed: {str(e)}"}]

    def search_steam(term: str):
        try:
            url = f"https://store.steampowered.com/api/storesearch/?term={urllib.parse.quote(term)}&l=english&cc=US"
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=8) as r:
                data = json.loads(r.read().decode("utf-8"))
            items = data.get("items", [])[:5]
            return [
                {"name": i.get("name"), "id": i.get("id"), "price": i.get("price", {}).get("final", 0) / 100}
                for i in items
            ]
        except Exception as e:
            return [{"error": str(e)}]

    def fetch_page_content(url: str, max_chars: int = 4000):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=10) as r:
                html = r.read().decode("utf-8", errors="ignore")
            soup = BeautifulSoup(html, "html.parser")
            for tag in soup(["script", "style", "nav", "footer", "header", "svg", "noscript"]):
                tag.decompose()
            text = soup.get_text(separator="\n", strip=True)
            text = re.sub(r"\n{3,}", "\n\n", text)
            return text[:max_chars]
        except Exception as e:
            return f"Error fetching {url}: {str(e)}"

    def handle_call_tool(tool_name: str, arguments: dict):
        if tool_name == "web_search":
            q = arguments.get("query", "")
            n = int(arguments.get("num_results", 5))
            return json.dumps(run_duckduckgo_search(q, max_results=n), indent=2)
        elif tool_name == "search_games":
            keywords = arguments.get("keywords", "")
            steam_hits = search_steam(keywords)
            web_hits = run_duckduckgo_search(f"site:itch.io {keywords}", max_results=4)
            return json.dumps({"keywords": keywords, "steam": steam_hits, "itch": web_hits}, indent=2)
        elif tool_name == "fetch_page":
            return fetch_page_content(arguments.get("url", ""))
        return f"Unknown tool: {tool_name}"

    def send_response(response_dict):
        sys.stdout.write(json.dumps(response_dict) + "\n")
        sys.stdout.flush()

    def main():
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            try:
                req = json.loads(line)
            except Exception:
                continue

            method = req.get("method")
            msg_id = req.get("id")

            if method == "initialize":
                send_response({
                    "jsonrpc": "2.0",
                    "id": msg_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {"tools": {}},
                        "serverInfo": {"name": "agent-mcp-search", "version": "1.0.0"}
                    }
                })
            elif method == "notifications/initialized":
                pass
            elif method == "ping":
                send_response({"jsonrpc": "2.0", "id": msg_id, "result": {}})
            elif method == "tools/list":
                send_response({
                    "jsonrpc": "2.0",
                    "id": msg_id,
                    "result": {
                        "tools": [
                            {
                                "name": "web_search",
                                "description": "Search DuckDuckGo for live articles and discussions.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "query": {"type": "string", "description": "Search query"},
                                        "num_results": {"type": "integer", "default": 5}
                                    },
                                    "required": ["query"]
                                }
                            },
                            {
                                "name": "search_games",
                                "description": "Search Steam store API and itch.io for mechanics and titles.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "keywords": {"type": "string", "description": "Keywords or mechanics to look up"}
                                    },
                                    "required": ["keywords"]
                                }
                            },
                            {
                                "name": "fetch_page",
                                "description": "Scrape readable text from a URL.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "url": {"type": "string", "description": "URL to scrape"}
                                    },
                                    "required": ["url"]
                                }
                            }
                        ]
                    }
                })
            elif method == "tools/call":
                p = req.get("params", {})
                res = handle_call_tool(p.get("name", ""), p.get("arguments", {}))
                send_response({
                    "jsonrpc": "2.0",
                    "id": msg_id,
                    "result": {"content": [{"type": "text", "text": res}]}
                })
            elif msg_id is not None:
                send_response({
                    "jsonrpc": "2.0",
                    "id": msg_id,
                    "error": {"code": -32601, "message": f"Method {method} not found"}
                })

    if __name__ == "__main__":
        main()
  '';

  # Manifest file collecting all configured agents declaratively
  agentsManifestData = mapAttrs (name: a: {
    inherit (a) name description model temperature systemPrompt mcpServers interactiveTool;
    rulesFile = if a.rulesFile != null then toString a.rulesFile else null;
    hasCustomTask = a.taskScript != null;
  }) cfg.agents;

  # MCP servers manifest formatted for standard MCP clients (Claude / Roo Code / Cline)
  mcpConfigData = {
    mcpServers = mapAttrs (name: s: {
      command = s.command;
      args = s.args;
      env = s.env;
    }) cfg.mcp.servers;
  };

  # Unified CLI controller for modular agents
  aiAgentCli = pkgs.writeScriptBin "ai-agent" ''
    #!${pythonEnv}/bin/python3
    import argparse
    import json
    import os
    import subprocess
    import sys
    import urllib.request
    from urllib.parse import quote

    MANIFEST_PATH = os.path.expanduser("~/.config/ai-agent/manifest.json")
    LITELLM_CONFIG = os.path.expanduser("~/.config/litellm/config.yaml")
    PROXY_BASE = os.environ.get("OPENAI_API_BASE", "http://127.0.0.1:${toString cfg.litellm.port}/v1")

    def load_manifest():
        if not os.path.exists(MANIFEST_PATH):
            print(f"Error: Manifest not found at {MANIFEST_PATH}")
            sys.exit(1)
        with open(MANIFEST_PATH, "r") as f:
            return json.load(f)

    def cmd_list(args):
        manifest = load_manifest()
        print("\nAvailable Configured AI Agents:\n")
        for key, info in manifest.items():
            print(f"  • {key:<18} [{info.get('model', 'default')}]")
            print(f"    {info.get('description', 'No description')}")
            servers = ", ".join(info.get("mcpServers", []))
            print(f"    MCP Tools: {servers if servers else 'none'}\n")

    def query_proxy_chat(model: str, system_prompt: str, user_prompt: str, temperature: float = 0.7):
        api_key = os.environ.get("OPENAI_API_KEY", os.environ.get("GEMINI_API_KEY", "sk-litellm-proxy"))
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": temperature
        }
        req = urllib.request.Request(
            f"{PROXY_BASE}/chat/completions",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"}
        )
        with urllib.request.urlopen(req, timeout=90) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data["choices"][0]["message"]["content"]

    def cmd_run(args):
        manifest = load_manifest()
        agent = manifest.get(args.agent)
        if not agent:
            print(f"Error: Unknown agent '{args.agent}'. Run 'ai-agent list' to see available agents.")
            sys.exit(1)

        custom_task_file = os.path.expanduser(f"~/.config/ai-agent/tasks/{args.agent}.py")
        if os.path.exists(custom_task_file):
            cmd = ["${pythonEnv}/bin/python3", custom_task_file] + args.extra_args
            sys.exit(subprocess.call(cmd))

        prompt = " ".join(args.extra_args) if args.extra_args else "Run default routine."
        sys_prompt = agent.get("systemPrompt", "")
        rules_path = agent.get("rulesFile")
        if rules_path and os.path.exists(rules_path):
            with open(rules_path, "r") as rf:
                sys_prompt = rf.read() + "\n\n" + sys_prompt

        print(f"Running agent '{args.agent}' with model '{agent.get('model')}'...")
        try:
            result = query_proxy_chat(
                model=agent.get("model", "gemini-flash"),
                system_prompt=sys_prompt,
                user_prompt=prompt,
                temperature=agent.get("temperature", 0.7)
            )
            print("\n" + result)
        except Exception as e:
            print(f"Error connecting to agent backend ({PROXY_BASE}): {e}")
            print("Tip: Start the LiteLLM proxy with 'ai-agent proxy start'.")

    def cmd_chat(args):
        manifest = load_manifest()
        agent = manifest.get(args.agent)
        if not agent:
            print(f"Error: Unknown agent '{args.agent}'. Run 'ai-agent list' to see available agents.")
            sys.exit(1)

        tool = agent.get("interactiveTool", "aider")
        model = agent.get("model", "gemini-flash")
        rules_path = agent.get("rulesFile")

        if tool == "aider":
            env = os.environ.copy()
            env["OPENAI_API_BASE"] = PROXY_BASE
            env.setdefault("OPENAI_API_KEY", "sk-litellm-proxy")

            aider_model = f"openai/{model}"
            cmd = ["${pkgs.aider-chat}/bin/aider", "--model", aider_model]
            if rules_path and os.path.exists(rules_path):
                cmd += ["--read", rules_path]
            cmd += args.extra_args
            sys.exit(subprocess.call(cmd, env=env))
        else:
            print(f"Interactive tool '{tool}' not implemented; launching aider.")
            cmd_chat(args)

    def cmd_proxy(args):
        action = args.action
        if action == "start":
            print(f"Launching LiteLLM proxy on port ${toString cfg.litellm.port}...")
            cmd = ["${pkgs.litellm}/bin/litellm", "--config", LITELLM_CONFIG, "--port", "${toString cfg.litellm.port}"]
            subprocess.call(cmd)
        elif action == "status":
            try:
                with urllib.request.urlopen(f"{PROXY_BASE}/models", timeout=3) as resp:
                    data = json.loads(resp.read().decode("utf-8"))
                    print(f"LiteLLM proxy is active. Models: {[m.get('id') for m in data.get('data', [])]}")
            except Exception as e:
                print(f"LiteLLM proxy is NOT responding on {PROXY_BASE} ({e})")

    def main():
        parser = argparse.ArgumentParser(description="Modular AI Agent System Manager")
        sub = parser.add_subparsers(dest="command")

        sub.add_parser("list", help="List all configured agents")

        p_run = sub.add_parser("run", help="Execute an agent task or workflow")
        p_run.add_argument("agent", help="Agent identifier")
        p_run.add_argument("extra_args", nargs="*", help="Arguments or prompt to forward")

        p_chat = sub.add_parser("chat", help="Start an interactive session with an agent")
        p_chat.add_argument("agent", help="Agent identifier")
        p_chat.add_argument("extra_args", nargs="*", help="Flags to forward to interactive runner")

        p_proxy = sub.add_parser("proxy", help="Manage LiteLLM rotating proxy")
        p_proxy.add_argument("action", choices=["start", "status"], help="Proxy action")

        args, remaining = parser.parse_known_args()
        if not args.command:
            parser.print_help()
            sys.exit(0)

        if args.command == "list":
            cmd_list(args)
        elif args.command == "run":
            cmd_run(args)
        elif args.command == "chat":
            cmd_chat(args)
        elif args.command == "proxy":
            cmd_proxy(args)

    if __name__ == "__main__":
        main()
  '';

  # Submodule representing an individual configurable AI agent
  agentSubmodule = types.submodule ({ name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = "Unique agent identifier.";
      };
      description = mkOption {
        type = types.str;
        default = "";
        description = "Brief summary of what this agent does.";
      };
      model = mkOption {
        type = types.str;
        default = "gemini-flash";
        description = "Target model routed through LiteLLM or provider.";
      };
      temperature = mkOption {
        type = types.float;
        default = 0.7;
        description = "LLM temperature setting.";
      };
      systemPrompt = mkOption {
        type = types.lines;
        default = "";
        description = "System prompt instructions for the agent.";
      };
      rulesFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional path to markdown rules or guidelines.";
      };
      mcpServers = mkOption {
        type = types.listOf types.str;
        default = [ "web-research" ];
        description = "List of MCP servers accessible to this agent.";
      };
      interactiveTool = mkOption {
        type = types.enum [ "aider" "chat" ];
        default = "aider";
        description = "Tool to spawn when running `ai-agent chat <name>`.";
      };
      taskScript = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = "Python task code executed when `ai-agent run <name>` is called.";
      };
    };
  });

  # Submodule representing an MCP server registration
  mcpServerSubmodule = types.submodule ({ name, ... }: {
    options = {
      command = mkOption {
        type = types.str;
        description = "Executable command for the MCP stdio server.";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Command-line arguments for the MCP server.";
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables passed to the server.";
      };
    };
  });
in
{
  options.aiAgents = {
    enable = mkEnableOption "Modular AI Agent framework with LiteLLM and MCP support";

    litellm = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable LiteLLM local proxy with automatic key failover.";
      };
      port = mkOption {
        type = types.port;
        default = 4000;
        description = "Port on which LiteLLM proxy listens.";
      };
      cooldownTime = mkOption {
        type = types.int;
        default = 60;
        description = "Cooldown time in seconds after receiving 429 quota exhaustion.";
      };
      numRetries = mkOption {
        type = types.int;
        default = 3;
        description = "Number of retry attempts when failing over keys.";
      };
      models = mkOption {
        type = types.listOf (types.attrsOf types.anything);
        default = [
          {
            model_name = "gemini-flash";
            litellm_params = {
              model = "gemini/gemini-2.5-flash";
              api_key = "os.environ/GEMINI_API_KEY_1";
            };
          }
          {
            model_name = "gemini-flash";
            litellm_params = {
              model = "gemini/gemini-2.5-flash";
              api_key = "os.environ/GEMINI_API_KEY_2";
            };
          }
          {
            model_name = "gemini-flash";
            litellm_params = {
              model = "gemini/gemini-2.5-flash";
              api_key = "os.environ/GEMINI_API_KEY_3";
            };
          }
          {
            model_name = "groq-llama";
            litellm_params = {
              model = "groq/llama-3.3-70b-versatile";
              api_key = "os.environ/GROQ_API_KEY";
            };
          }
        ];
        description = "List of model routing mappings for LiteLLM.";
      };
      systemdService = mkOption {
        type = types.bool;
        default = false;
        description = "Run the LiteLLM proxy as a persistent user systemd service.";
      };
    };

    mcp = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Model Context Protocol server registrations.";
      };
      servers = mkOption {
        type = types.attrsOf mcpServerSubmodule;
        default = {
          "web-research" = {
            command = "${mcpSearchServer}/bin/agent-mcp-search";
            args = [];
            env = {};
          };
        };
        description = "Declared MCP servers available to agents and editors.";
      };
    };

    agents = mkOption {
      type = types.attrsOf agentSubmodule;
      default = {};
      description = "Attribute set of modular AI agents.";
    };
  };

  config = mkIf cfg.enable {
    # Default agent declarations
    aiAgents.agents = {
      murder-board = mkDefault {
        name = "murder-board";
        description = "Autonomous Jesse Schell & Mark Cerny 3-month Idea Murder Board";
        model = "gemini-flash";
        temperature = 0.7;
        systemPrompt = ''
          You are an adversarial game design agent and market researcher.
          Your goal is to invent hyper-addictive, mechanically novel 2D games deliverable by a solo developer in 3 months.
          Do not give standard tropes. Apply Jesse Schell's Lenses (Lens 15: Toy First, Lens 33: Triangularity, Lens 43: Elegance)
          and Mark Cerny's Method (< 4 verbs, 7-day toy prototype verification).
        '';
        rulesFile = pkgs.writeText "murder-board-rules.md" ''
          # Idea Murder Board Protocol
          1. Verb Inversion & Schell's Lenses: Describe tactile toy verbs and high/low risk trade-offs without aesthetics.
          2. Murder Board: Query Steam & itch.io for clones. Discard unoriginal loops immediately.
          3. Evolutionary Mutation: Invert assumptions, strip inputs, or introduce systemic emergence.
          4. Feasibility Audit: Ensure scope can be built in 3 months by a solo developer.
        '';
        mcpServers = [ "web-research" ];
        interactiveTool = "aider";
        taskScript = ''
          import json
          import os
          import time
          import urllib.request
          from urllib.parse import quote

          PROXY_URL = os.environ.get("OPENAI_API_BASE", "http://127.0.0.1:${toString cfg.litellm.port}/v1")
          API_KEY = os.environ.get("OPENAI_API_KEY", "sk-litellm-proxy")

          def call_llm(user_prompt):
              payload = {
                  "model": "gemini-flash",
                  "messages": [
                      {"role": "system", "content": "You are an adversarial game designer. Invent hyper-novel 2D mechanics."},
                      {"role": "user", "content": user_prompt}
                  ],
                  "temperature": 0.7
              }
              req = urllib.request.Request(
                  f"{PROXY_URL}/chat/completions",
                  data=json.dumps(payload).encode("utf-8"),
                  headers={"Content-Type": "application/json", "Authorization": f"Bearer {API_KEY}"}
              )
              with urllib.request.urlopen(req, timeout=60) as resp:
                  return json.loads(resp.read().decode("utf-8"))["choices"][0]["message"]["content"]

          print("Synthesizing toy-first concept...")
          draft = call_llm("Propose a single 2D game mechanic based on Jesse Schell's Lens 15 (Toy First) and Lens 43 (Elegance). List 3 market search keywords.")
          print("\nDraft Concept:\n" + draft[:300] + "...\n")

          with open("candidates.md", "a") as f:
              f.write(f"\n## Idea Candidate ({time.strftime('%Y-%m-%d %H:%M')})\n{draft}\n\n---\n")
          print("Saved candidate to candidates.md")
        '';
      };

      coder = mkDefault {
        name = "coder";
        description = "Context-aware terminal coding agent with Aider";
        model = "gemini-flash";
        temperature = 0.2;
        systemPrompt = "You are an expert systems and software engineering agent. Write minimal, clean, robust code.";
        mcpServers = [ "web-research" ];
        interactiveTool = "aider";
      };
    };

    home.packages = [
      pkgs.aider-chat
      pkgs.litellm
      pythonEnv
      mcpSearchServer
      aiAgentCli
    ];

    # Write out task scripts for agents that specify custom tasks
    xdg.configFile = mapAttrs' (name: a:
      nameValuePair "ai-agent/tasks/${name}.py" {
        text = if a.taskScript != null then a.taskScript else "";
      }
    ) (filterAttrs (_: a: a.taskScript != null) cfg.agents);

    # Declarative agent manifest read dynamically by `ai-agent`
    xdg.configFile."ai-agent/manifest.json".text = builtins.toJSON agentsManifestData;

    # LiteLLM configuration file
    xdg.configFile."litellm/config.yaml".text = ''
      model_list:
      ${lib.concatMapStrings (m: ''
        - model_name: ${m.model_name}
          litellm_params:
            model: ${m.litellm_params.model}
            api_key: ${m.litellm_params.api_key}
      '') cfg.litellm.models}
      router_settings:
        routing_strategy: "usage-based-routing"
        num_retries: ${toString cfg.litellm.numRetries}
        retry_after: 5
        cooldown_time: ${toString cfg.litellm.cooldownTime}
    '';

    # Export MCP configurations to standard locations
    xdg.configFile."mcp/servers.json".text = builtins.toJSON mcpConfigData;
    xdg.configFile."mcp/config.json".text = builtins.toJSON mcpConfigData;
    home.file.".config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_mcp_settings.json".text = builtins.toJSON mcpConfigData;

    # Optional systemd user service for running the LiteLLM proxy in the background
    systemd.user.services.litellm-proxy = mkIf cfg.litellm.systemdService {
      Unit = {
        Description = "LiteLLM Key Rotation & Fallback Proxy";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${pkgs.litellm}/bin/litellm --config %h/.config/litellm/config.yaml --port ${toString cfg.litellm.port}";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Convenient shortcuts
    home.shellAliases = {
      agent = "ai-agent";
      game-agent = "ai-agent run murder-board";
      code-agent = "ai-agent chat coder";
    };
  };
}
