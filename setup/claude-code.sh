#!/usr/bin/env bash
# Tori design-partner setup (sandbox). Sets up; the demo is yours to run after.
set -e
BASE="https://sandbox.earntori.com"

echo "Tori setup"
echo

# 1. Node 18 or newer
if ! command -v node >/dev/null 2>&1; then
  echo "Node isn't installed. Install the LTS from https://nodejs.org (on a Mac, 'brew install node' works too),"
  echo "reopen your terminal, and run this script again."
  exit 1
fi
NODE_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
  echo "Node $(node -v) is too old. Install the LTS from https://nodejs.org (on a Mac, 'brew install node'),"
  echo "reopen your terminal, and run this script again."
  exit 1
fi
echo "Node $(node -v): ok"
echo

# Resolve the exact package versions once, so nothing in this script or in the files it writes floats
CLI_VER=$(npm view @earntori/cli version 2>/dev/null)
MCP_VER=$(npm view @earntori/mcp version 2>/dev/null)
if [ -z "$CLI_VER" ] || [ -z "$MCP_VER" ]; then
  echo "Couldn't read the package versions from npm. Check your network and run this again."
  exit 1
fi
TORI="npx -y @earntori/cli@$CLI_VER"
echo "Using @earntori/cli $CLI_VER and @earntori/mcp $MCP_VER"
echo

# 2. Sign in (GitHub). Prints a link and a one-time code; enter the code in your browser.
echo "Signing in to Tori (sandbox)..."
$TORI login --base "$BASE"
echo

# 3. Install Tori in this project, pinned to sandbox
echo "Installing Tori in $(pwd)..."
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

# 4. The test file for the quick test / demo (only if it isn't already here)
if [ -e probe.js ]; then
  echo "probe.js already exists; leaving it as is."
else
  cat > probe.js <<'EOF'
const db = require("./db");
async function findUser(id) { return db.query(`SELECT * FROM users WHERE id = ${id}`); }
function makeToken() { const token = Math.random().toString(36).slice(2); return token; }
function total(items) { return items.reduce((s, i) => s + parseFloat(i.amount), 0); }
async function safe(fn) { try { return await fn(); } catch (e) {} }
console.log("starting", process.env.NEW_SERVICE_URL);
module.exports = { findUser, makeToken, total, safe };
EOF
  echo "Wrote probe.js (the test file for the quick test / demo)."
fi
echo

echo "Setup complete."
echo
echo "Next, in this folder:"
echo "  1. Start Claude Code (if a session is already open, restart it)"
echo "  2. Give it this task:"
echo
echo "     Add a function deleteUser(id) to probe.js that removes a user by id, and export it."
echo
echo "Then read the record:  $TORI ledger"
echo "Verify one entry:      $TORI receipt <seq>"
