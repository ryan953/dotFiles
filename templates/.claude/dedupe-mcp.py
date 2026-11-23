#!/usr/bin/env python3
"""SessionStart hook: disable a project's .mcp.json servers that duplicate a
global server (claude.ai connector, user-scope server, or enabled plugin).

Duplicates are written to <project>/.claude/settings.local.json under
`disabledMcpjsonServers`. The list is only ever added to, so manual entries
are kept.
"""

import json
import os
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlsplit

HOME = os.path.expanduser("~")
CLAUDE_JSON = os.path.join(HOME, ".claude.json")
SETTINGS_JSON = os.path.join(HOME, ".claude", "settings.json")
INSTALLED_PLUGINS = os.path.join(HOME, ".claude", "plugins", "installed_plugins.json")
CACHE_FILE = os.path.join(HOME, ".cache", "claude-dedupe-mcp", "connectors.json")
CACHE_MAX_AGE = 24 * 60 * 60
CONNECTOR_PREFIX = "claude.ai "


def read_json(path, default=None):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def normalize_name(name):
    return "".join(c for c in name.lower() if c.isalnum())


def url_key(url):
    parts = urlsplit(url)
    segments = [s for s in parts.path.split("/") if s]
    return parts.hostname or "", segments


def urls_match(a, b):
    # Same host, and one path is a prefix of the other: `/mcp` and
    # `/mcp/sentry` are the same service with a different default scope.
    host_a, path_a = url_key(a)
    host_b, path_b = url_key(b)
    if not host_a or host_a != host_b:
        return False
    shorter, longer = sorted((path_a, path_b), key=len)
    return longer[: len(shorter)] == shorter


def server_identity(config):
    if config.get("url"):
        return ("url", config["url"])
    if config.get("command"):
        return ("cmd", " ".join([config["command"], *config.get("args", [])]))
    return None


def refresh_connector_cache():
    # `claude mcp list` health-checks every server and takes a few seconds,
    # so run it detached and use the result on the next session start.
    script = (
        "import json,os,subprocess,sys\n"
        "out=subprocess.run(['claude','mcp','list'],capture_output=True,text=True,"
        "cwd=sys.argv[2],timeout=120).stdout\n"
        "rows=[]\n"
        "for line in out.splitlines():\n"
        "  if not line.startswith(%r) or ': ' not in line: continue\n"
        "  name,rest=line.split(': ',1)\n"
        "  rows.append({'name':name,'url':rest.split(' - ')[0].split(' (')[0].strip()})\n"
        "os.makedirs(os.path.dirname(sys.argv[1]),exist_ok=True)\n"
        "tmp=sys.argv[1]+'.tmp'\n"
        "json.dump(rows,open(tmp,'w'))\n"
        "os.replace(tmp,sys.argv[1])\n"
    ) % CONNECTOR_PREFIX
    subprocess.Popen(
        [sys.executable, "-c", script, CACHE_FILE, tempfile.mkdtemp()],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def connector_servers(claude_json):
    try:
        stale = time.time() - os.path.getmtime(CACHE_FILE) > CACHE_MAX_AGE
    except OSError:
        stale = True
    if stale:
        refresh_connector_cache()

    cached = read_json(CACHE_FILE)
    if cached is not None:
        return [(row["name"], {"url": row["url"]}) for row in cached]
    # Before the first cache refresh finishes, only names are known.
    return [(name, {}) for name in claude_json.get("claudeAiMcpEverConnected", [])]


def plugin_servers():
    enabled = read_json(SETTINGS_JSON, {}).get("enabledPlugins", {})
    installed = read_json(INSTALLED_PLUGINS, {}).get("plugins", {})
    servers = []
    for plugin_id, is_enabled in enabled.items():
        if not is_enabled or plugin_id not in installed:
            continue
        plugin_name = plugin_id.split("@")[0]
        for install in installed[plugin_id]:
            root = install.get("installPath", "")
            manifest = read_json(os.path.join(root, ".claude-plugin", "plugin.json"), {})
            configs = manifest.get("mcpServers")
            if not isinstance(configs, dict):
                configs = read_json(os.path.join(root, ".mcp.json"), {}).get("mcpServers", {})
            for name, config in configs.items():
                servers.append((f"plugin:{plugin_name}:{name}", config))
    return servers


def global_servers(claude_json, project_dir):
    servers = connector_servers(claude_json)
    servers += list(claude_json.get("mcpServers", {}).items())
    servers += plugin_servers()
    # A global server turned off in this project via /mcp is not a copy here.
    disabled = set(
        claude_json.get("projects", {}).get(project_dir, {}).get("disabledMcpServers", [])
    )
    return [(name, config) for name, config in servers if name not in disabled]


def find_duplicate(name, config, globals_):
    identity = server_identity(config)
    for global_name, global_config in globals_:
        global_identity = server_identity(global_config)
        if identity and global_identity and identity[0] == global_identity[0]:
            if identity[0] == "url" and urls_match(identity[1], global_identity[1]):
                return global_name
            if identity[0] == "cmd" and identity[1] == global_identity[1]:
                return global_name
        elif global_identity is None:
            short = global_name.removeprefix(CONNECTOR_PREFIX)
            if normalize_name(short) == normalize_name(name):
                return global_name
    return None


def main():
    try:
        hook_input = json.load(sys.stdin)
    except ValueError:
        hook_input = {}
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or hook_input.get("cwd") or os.getcwd()

    project_servers = read_json(os.path.join(project_dir, ".mcp.json"), {}).get("mcpServers", {})
    if not project_servers:
        return

    claude_json = read_json(CLAUDE_JSON, {})
    globals_ = global_servers(claude_json, project_dir)

    local_path = os.path.join(project_dir, ".claude", "settings.local.json")
    local = read_json(local_path, {})
    already = set(local.get("disabledMcpjsonServers", []))

    added = []
    for name, config in project_servers.items():
        if name in already:
            continue
        match = find_duplicate(name, config, globals_)
        if match:
            added.append((name, match))
    if not added:
        return

    local["disabledMcpjsonServers"] = sorted(already | {name for name, _ in added})
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    tmp = local_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(local, f, indent=2)
        f.write("\n")
    os.replace(tmp, local_path)

    summary = ", ".join(f"{name} (same as {match})" for name, match in added)
    print(json.dumps({"systemMessage": f"Disabled duplicate .mcp.json servers: {summary}"}))


if __name__ == "__main__":
    main()
