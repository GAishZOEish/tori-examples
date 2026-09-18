# Getting started

Tori adds a check to your coding agent: before it calls a task done, its integration code is checked against a small set of rules, findings come with the fix, and verified fixes earn credits toward a budgeted key for your AI tools. Every check, finding, fix, and reward is written to an append-only log with a signed receipt.

Works in Claude Code (checks run automatically at the stop point) and Cursor (the agent calls the tools).

## Requirements

- Node 18 or later
- Claude Code or Cursor
- A git repo you're working in
- JavaScript / TypeScript projects today

## Install

```
npx @earntori/cli login
```

Prints a GitHub sign-in link and a one-time code; open the link and enter the code. The session is stored in `~/.tori/config.json`.

```
cd your-project
npx @earntori/cli init
```

Adds Tori's MCP server to Claude Code or Cursor for this project. In Claude Code it also installs two hooks: one that runs the checks when the agent stops, and one that reminds the agent at session start that the checks and the log are there.

## What happens next

Work normally. When the agent finishes a task in Claude Code, the Stop hook runs the checks on the code it changed.

- Clean: the task completes
- Findings: the agent is told what's wrong and how to fix it, and the task stays open until it's fixed or you deliberately defer it

In Cursor, ask the agent to run the checks, or run them yourself:

```
npx @earntori/cli check
```

## Read the log

```
npx @earntori/cli ledger
```

Shows this project's history: findings opened and resolved, what was deferred and why, recent runs, recent rewards. The agent reads the same thing through the `ledger_query` tool.

## Verify a receipt

Every entry on the log has a signed receipt. To check one on your own machine:

```
npx @earntori/cli receipt <n>
```

Fetches the entry, recomputes its hash, and verifies the signature against the public key Tori publishes. It prints `VERIFIED`, or `UNSIGNED` / `INVALID` with the reason.

## Deferring a finding

If a finding doesn't apply, the agent can defer it with a reason, or you can add `// tori-ignore` above the line. Deferrals are recorded and never earn credits. Removing the comment reopens the finding.

## Credits and the budgeted key

Verified fixes earn credits. Credits become a spend-capped API key you can use in Cursor, Claude Code, or anything OpenAI-compatible — a budget for your agent that follows the log.

```
npx @earntori/cli status
```

Shows your balance and your AI keys. Open findings and recent runs are in `ledger`.

## What's checked

Today: five rules for the mistakes agents make in integration code — webhook handlers that don't verify the signature, secrets or tokens written to logs, personal data written to logs, retried create/transfer/POST calls without an idempotency key, and hard-coded credentials. Rules are versioned; every finding records which version found it.

## Examples

Agents built on Tori, including a budgeted agent running on a capped key: ./examples/budgeted-agent

---

Built by BQ
