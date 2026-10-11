#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Todo
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Productivity
# @raycast.icon 󰄲

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v todoist >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "Todo" "todoist CLI is not installed"
  exit 1
fi

# Check if authenticated
if ! todoist l >/dev/null 2>&1; then
  ACTION=$(printf "Log in to Todoist (open terminal)\n" | vicinae dmenu --placeholder "Todoist requires your API Token")
  if [ -n "$ACTION" ]; then
    alacritty -e bash -c 'echo "Get your API token from: https://todoist.com/prefs/integrations"; echo; todoist; echo; read -p "Press Enter to close..."'
  fi
  exit 0
fi

# Autosync on initial startup (safely times out if offline)
if [ -z "$1" ]; then
  timeout 3s todoist sync >/dev/null 2>&1
fi

CURRENT_VIEW="${1:-Inbox}"
SCRIPT_PATH="$(realpath "$0")"

python3 - "$CURRENT_VIEW" "$SCRIPT_PATH" << 'EOF'
import os
import re
import subprocess
import sys

current_view = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else "Inbox"
script_path = sys.argv[2] if len(sys.argv) > 2 else sys.argv[0]

res = subprocess.run(["todoist", "l"], capture_output=True, text=True)
clean_output = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', res.stdout)
lines = clean_output.splitlines()

tasks = []
all_projects = {"Inbox"}

def normalize_project(proj: str) -> str:
    proj = proj.strip()
    if not proj:
        return "Inbox"
    if "/" in proj:
        parts = proj.split("/", 1)
        if parts[0].lower() == "inbox":
            return "Inbox"
        return parts[0]
    return proj

def badge_tags(content: str) -> str:
    # Replaces @tag with ' tag'
    return re.sub(r'@([a-zA-Z0-9_\-]+)', r' \1', content)

for line in lines[1:]:
    line = line.strip()
    if not line:
        continue

    m = re.match(r'^([0-9a-zA-Z_-]+)\s+(?:(p[1-4])\s+)?#([^\s]+)\s+(.*)$', line)
    if m:
        t_id = m.group(1)
        priority = m.group(2) or "p4"
        project = normalize_project(m.group(3))
        content = m.group(4).strip()
        all_projects.add(project)
        tasks.append({
            "id": t_id,
            "priority": priority,
            "project": project,
            "content": content,
        })
    else:
        tokens = line.split()
        if len(tokens) >= 2:
            t_id = tokens[0]
            proj = "Inbox"
            rest_tokens = []
            for tok in tokens[1:]:
                if tok.startswith("#") and proj == "Inbox":
                    proj = normalize_project(tok[1:])
                elif re.match(r'^p[1-4]$', tok):
                    pass
                else:
                    rest_tokens.append(tok)
            proj = normalize_project(proj)
            content = " ".join(rest_tokens)
            all_projects.add(proj)
            tasks.append({
                "id": t_id,
                "priority": "p4",
                "project": proj,
                "content": content,
            })

proj_res = subprocess.run(["todoist", "projects"], capture_output=True, text=True)
if proj_res.returncode == 0:
    for pline in re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', proj_res.stdout).splitlines()[1:]:
        pline = pline.strip()
        if pline:
            p_tokens = pline.split()
            pname = " ".join(p_tokens[1:]) if len(p_tokens) >= 2 else p_tokens[0]
            pname = pname.lstrip("#").strip()
            pname = normalize_project(pname)
            if pname:
                all_projects.add(pname)

is_all_view = current_view.lower() in ("all", "all projects")

if is_all_view:
    visible_tasks = sorted(
        tasks,
        key=lambda t: (0 if t["project"].lower() == "inbox" else 1, t["project"].lower(), t.get("priority", "p4"))
    )
else:
    visible_tasks = [
        t for t in tasks
        if t["project"].lower() == current_view.lower()
    ]
    visible_tasks.sort(key=lambda t: t.get("priority", "p4"))

menu_lines = []
task_lookup = {}

CHECKBOX_ICON = "󰄱"

for t in visible_tasks:
    content_display = badge_tags(t["content"])
    if is_all_view:
        display_line = f"{CHECKBOX_ICON}  [#{t['project']}] {content_display}"
    else:
        display_line = f"{CHECKBOX_ICON}  {content_display}"

    task_lookup.setdefault(display_line, []).append(t["id"])
    menu_lines.append(display_line)

if not visible_tasks:
    menu_lines.append(f"{CHECKBOX_ICON}  (No tasks in {current_view})")

if is_all_view:
    menu_lines.append("󰇮  View Inbox Only")
    menu_lines.append("󰉋  Switch Project [Current: All Projects]")
else:
    menu_lines.append("󱓞  View All Projects")
    menu_lines.append(f"󰉋  Switch Project [Current: {current_view}]")

menu_lines.append("󰐕  Add New Task")
menu_lines.append("󰑐  Sync Now")

placeholder = f"Todoist ({current_view}) — Select task to complete..." if not is_all_view else "Todoist (All Projects) — Select task..."
menu_input = "\n".join(menu_lines)

dmenu_proc = subprocess.run(
    ["vicinae", "dmenu", "--placeholder", placeholder],
    input=menu_input,
    text=True,
    capture_output=True
)

selected = dmenu_proc.stdout.strip()
if not selected:
    sys.exit(0)

if selected.startswith("󱓞  View All Projects"):
    os.execv("/usr/bin/env", ["/usr/bin/env", "bash", script_path, "All"])

if selected.startswith("󰇮  View Inbox Only"):
    os.execv("/usr/bin/env", ["/usr/bin/env", "bash", script_path, "Inbox"])

if selected.startswith("󰉋  Switch Project"):
    sorted_projects = sorted([p for p in all_projects if p.lower() != "inbox"], key=str.lower)
    proj_choices = ["󰇮  Inbox", "󱓞  All Projects"] + [f"󰉋  {p}" for p in sorted_projects]
    p_proc = subprocess.run(
        ["vicinae", "dmenu", "--placeholder", "Select project view..."],
        input="\n".join(proj_choices),
        text=True,
        capture_output=True
    )
    p_selected = p_proc.stdout.strip()
    if p_selected:
        if "All Projects" in p_selected:
            next_view = "All"
        elif "Inbox" in p_selected:
            next_view = "Inbox"
        else:
            next_view = re.sub(r'^[󰉋󰇮󱓞\s]+', '', p_selected).strip()
        os.execv("/usr/bin/env", ["/usr/bin/env", "bash", script_path, next_view])
    sys.exit(0)

if selected.startswith("󰐕  Add New Task"):
    add_proc = subprocess.run(
        ["vicinae", "dmenu", "--placeholder", "e.g. 'Buy milk tomorrow at 5pm' (Natural language supported!)"],
        input="",
        text=True,
        capture_output=True
    )
    title = add_proc.stdout.strip()
    if title:
        subprocess.run(["notify-send", "-i", "view-refresh-symbolic", "Todo", "Adding task..."])
        if not is_all_view and current_view.lower() != "inbox" and "#" not in title:
            title = f"{title} #{current_view}"
        add_run = subprocess.run(["todoist", "q", title], capture_output=True)
        if add_run.returncode != 0:
            subprocess.run(["todoist", "a", title], capture_output=True)
        subprocess.run(["todoist", "sync"], capture_output=True)
        subprocess.run(["notify-send", "-i", "checkbox-checked-symbolic", "Todo", f"Created: {title}"])
        os.execv("/usr/bin/env", ["/usr/bin/env", "bash", script_path, current_view])
    sys.exit(0)

if selected.startswith("󰑐  Sync Now"):
    subprocess.run(["notify-send", "-i", "view-refresh-symbolic", "Todo", "Syncing Todoist..."])
    sync_res = subprocess.run(["todoist", "sync"], capture_output=True)
    if sync_res.returncode == 0:
        subprocess.run(["notify-send", "-i", "view-refresh-symbolic", "Todo", "Sync completed"])
    else:
        subprocess.run(["notify-send", "-u", "critical", "-i", "dialog-warning", "Todo", "Sync failed"])
    os.execv("/usr/bin/env", ["/usr/bin/env", "bash", script_path, current_view])

task_ids = task_lookup.get(selected)
if task_ids:
    task_id = task_ids.pop(0)
    task_name = re.sub(r'^\s*󰄱\s+(\[#[^\]]+\]\s+)?', '', selected)
    task_name = re.sub(r'\s*', '', task_name).strip()
    subprocess.run(["todoist", "c", task_id], capture_output=True)
    subprocess.run(["notify-send", "-i", "checkbox-checked-symbolic", "Todo", f"Completed: {task_name}"])
    subprocess.Popen(["todoist", "sync"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.execv("/usr/bin/env", ["/usr/bin/env", "bash", script_path, current_view])
EOF
