#!/usr/bin/env bash
# Tori go-live: move this project from the sandbox to production. Your production record starts fresh.
set -e
BASE="https://www.earntori.com"

echo "Tori go-live"
echo

if [ ! -f .tori/project.json ]; then
  echo "This folder isn't set up with Tori yet. Run the setup script first."
  exit 1
fi

# Optional: --cli <version> --mcp <version> to choose the package versions explicitly
CLI_ARG=""; MCP_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --cli) CLI_ARG="$2"; shift 2 ;;
    --mcp) MCP_ARG="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Versions, in order: --cli/--mcp flags; the versions already pinned in this project's agent config
# (the ones you tested on sandbox); the current release from npm only if neither is available.
pinned() { grep -rhoE "@earntori/$1@[0-9][0-9.]*" .claude/settings.json .mcp.json .codex/config.toml .codex/hooks.json .cursor/mcp.json 2>/dev/null | head -1 | sed "s#.*@##"; }
CLI_VER="${CLI_ARG:-$(pinned cli)}"; MCP_VER="${MCP_ARG:-$(pinned mcp)}"
SRC="the versions pinned in this project"
if [ -z "$CLI_VER" ] || [ -z "$MCP_VER" ]; then
  CLI_VER="${CLI_VER:-$(npm view @earntori/cli version 2>/dev/null)}"
  MCP_VER="${MCP_VER:-$(npm view @earntori/mcp version 2>/dev/null)}"
  SRC="the current release from npm"
fi
if [ -n "$CLI_ARG" ] || [ -n "$MCP_ARG" ]; then SRC="the versions you passed"; fi
if [ -z "$CLI_VER" ] || [ -z "$MCP_VER" ]; then
  echo "Couldn't determine the package versions. Pass --cli <version> --mcp <version> and run this again."
  exit 1
fi
echo "Pinning production to $SRC"
TORI="npx -y @earntori/cli@$CLI_VER"
echo "Using @earntori/cli $CLI_VER and @earntori/mcp $MCP_VER"
echo

# 1. Sign in to production (GitHub). Prints a link and a one-time code; enter the code in your browser.
echo "Signing in to Tori (production)..."
$TORI login --base "$BASE"
echo

# 2. Re-pin this project to production (the sandbox pin is removed first so the switch is certain)
echo "Moving $(pwd) to production..."
rm -f .tori/project.json
$TORI init --base "$BASE"
echo

# Pin the agent config files init just wrote to the exact versions above
pin_file() {
  [ -f "$1" ] || return 0
  perl -pi -e 's#\@earntori/cli(?!\@)#\@earntori/cli\@'"$CLI_VER"'#g; s#\@earntori/mcp(?!\@)#\@earntori/mcp\@'"$MCP_VER"'#g' "$1"
  echo "  pinned $1"
}
echo "Pinning agent config to @earntori/cli@$CLI_VER and @earntori/mcp@$MCP_VER:"
pin_file .claude/settings.json
pin_file .codex/hooks.json
pin_file .codex/config.toml
pin_file .mcp.json
pin_file .cursor/mcp.json
echo

# 3. Standards don't carry over from the sandbox; turn them on here
echo "Enabling financial crime, payments and accounting on production..."
$TORI standards enable financial-crime payments accounting
echo

# 4. The sandbox test file never belongs in your production record
if [ -e probe.js ]; then
  rm -f probe.js
  echo "Removed probe.js (the sandbox test file)."
  echo
fi

echo "You're live. Restart your Claude Code or Codex session; from now on every task in this folder is checked on production."
echo
echo "Read the record:   $TORI ledger"
echo "Verify one entry:  $TORI receipt <seq>"
