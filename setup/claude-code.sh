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

# 2. Sign in (GitHub). Prints a link and a one-time code; enter the code in your browser.
echo "Signing in to Tori (sandbox)..."
npx @earntori/cli login --base "$BASE"
echo

# 3. Install Tori in this project, pinned to sandbox
echo "Installing Tori in $(pwd)..."
npx @earntori/cli init --base "$BASE" 
echo

# 4. The test file for your first task (only if it isn't already here)
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
  echo "Wrote probe.js (the test file for your first task)."
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
echo "Then read the record:  npx @earntori/cli ledger"
echo "Verify one entry:      npx @earntori/cli receipt <seq>"
