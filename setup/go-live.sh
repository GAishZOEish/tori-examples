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

# 1. Sign in to production (GitHub). Prints a link and a one-time code; enter the code in your browser.
echo "Signing in to Tori (production)..."
npx @earntori/cli login --base "$BASE"
echo

# 2. Re-pin this project to production (the sandbox pin is removed first so the switch is certain)
echo "Moving $(pwd) to production..."
rm -f .tori/project.json
npx @earntori/cli init --base "$BASE"
echo

# 3. Standards don't carry over from the sandbox; turn them on here
echo "Enabling financial crime and accounting on production..."
npx @earntori/cli standards enable financial-crime accounting
echo

# 4. The sandbox test file never belongs in your production record
if [ -e probe.js ]; then
  rm -f probe.js
  echo "Removed probe.js (the sandbox test file)."
  echo
fi

echo "You're live. Restart your Claude Code or Codex session; from now on every task in this folder is checked on production."
echo
echo "Read the record:   npx @earntori/cli ledger"
echo "Verify one entry:  npx @earntori/cli receipt <seq>"
