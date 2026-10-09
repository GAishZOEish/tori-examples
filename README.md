# Getting started

Tori holds your coding agents to a standard. Before an agent calls a task done, the work it hands back is checked against your coding standards and the standards your industry is held to; findings come with the fix, and the agent applies it. Everything the agent does is written to an append-only log with a signed receipt you can verify offline and show whoever needs proof; the agent reads that log at the start of every session.

Works with agents you use off the shelf — Claude Code, Cursor, Codex, Claude Cowork, Claude chat — and agents you build.

## Requirements

- Node 18 or later
- A GitHub account (sign-in)
- Checks cover JavaScript / TypeScript projects today

## Sign in

```
npx @earntori/cli login
```

Prints a GitHub sign-in link and a one-time code. The session is stored in `~/.tori/config.json`.

## Coding agents (CLI and IDE) — Claude Code, Codex, Cursor

```
cd your-project
npx @earntori/cli init
```

Adds Tori's tools to Claude Code, Cursor and Codex for this project. In Claude Code and Codex the checks also run automatically when the agent stops, and the agent gets a one-line reminder at session start to read the log first. Restart the session (in Codex, run `/hooks` once to trust the two hooks). From then on:

- The agent's work is checked against your coding standards before a task completes; serious findings block the task until fixed or deferred, the rest are recorded
- If a finding doesn't apply, the agent defers it with your reason (or you add a `// tori-ignore: reason` comment); deferrals are logged
- In Cursor, ask the agent to run the checks, or run `npx @earntori/cli check` yourself

The coding standards are OWASP- and CWE-aligned, and each finding comes with its fix. Domain standards for regulated work turn on per project, and you add your own rules. `standards` shows what's available and what's on for this project:

```
npx @earntori/cli standards
npx @earntori/cli standards enable privacy accessibility
npx @earntori/cli rules add "api routes must include requireAuth"
npx @earntori/cli rules add "No console.log outside dev paths."
```

`rules add` tells you whether Tori can enforce the rule as written or will record it for the agent to follow. The agent is held to the enabled standards and your rules from the next check on.

## Desktop agents — Claude (Chat, Cowork)

```
npx @earntori/cli connector new --label cowork
```

Prints a URL once. In Claude → Settings → Connectors → Add custom connector → paste the whole URL. From then on the agent reads the log at the start of a session, checks its work against your standards and rules before it calls a task done, and records what it did with a receipt each time. To set the standards and rules for this connector, add `--connector cowork` to the `standards` and `rules` commands above. The URL is the secret; revoke it any time with `npx @earntori/cli connector revoke <id>`.

## Agents you build

Mint the agent's key; it is both its model key and its Tori identity:

```
npx @earntori/cli key --limit 5 --write env
```

When you add an agent you built, the first thing Tori does is check its code. Run `npx @earntori/cli init` in the agent's repo and the coding agent you build with gets the findings with their fixes, applies them, and can't finish with one open.

JavaScript / TypeScript, with `@earntori/sdk` 0.3.0 or later — read the log first, record an intent before an action that matters, an outcome after it:

```js
import Tori from "@earntori/sdk";
const tori = new Tori({ apiKey: process.env.OPENAI_API_KEY });

const before = await tori.ledgerQuery({ include: ["open_findings", "waived", "head"] });

const { action_id, receipt } = await tori.journal.intent({ summary: "Post invoice INV-42 to AP", ref: { type: "invoice", id: "INV-42" } });
try {
  await postInvoice(inv, { headers: tori.journal.headers(action_id) });
  await tori.journal.outcome({ action_id, summary: "Posted INV-42; entry 8812" });
} catch (e) {
  await tori.journal.outcome({ action_id, summary: `Failed: ${e.message}` });
  throw e;
}
```

Any other language: three HTTP endpoints on `https://www.earntori.com`, bearer = the same key — `POST /api/v1/journal/append`, `GET /api/v1/ledger/query`, `GET /api/v1/ledger/receipts/{seq}`.

Already have an agent? In Claude Code, the plugin checks its code first and then adds the calls at the points that matter (money, external writes, messages, deletes, paid calls, approval gates):

```
/plugin marketplace add GAishZOEish/tori-examples
/plugin install tori-accountability@tori
/tori-accountability:add-tori-accountability path/to/agent.js
```

Worked example: [examples/budgeted-agent](./examples/budgeted-agent) — an agent loop on a capped key, every model call logged.

## Reading what your agents did

| Want to | Do |
| --- | --- |
| See a project's history | `npx @earntori/cli ledger` — newest first, one line per entry with its receipt; `--project all` for everything you own |
| See what this project is held to | `npx @earntori/cli standards` and `npx @earntori/cli rules` |
| Let an agent read it             | It calls `ledger_query`; with `include` it gets open findings, deferrals, recent runs and recent fixes                 |
| Verify one entry | `npx @earntori/cli receipt <seq>` — checks the entry against Tori's published key and prints `VERIFIED` |
| Follow one action                | `ledger_query { action_id }` — the intent, any findings on it, and its outcome                                        |
| Keys                             | `npx @earntori/cli status`                                                                                             |

## Keys

An agent you build runs on a spend-capped key you mint with `npx @earntori/cli key --limit 5 --write env`. The key works anywhere the OpenAI API works (base URL `https://openrouter.ai/api/v1`, any major model): Cursor, Claude Code, your own code. When its cap is spent it returns 401 and the agent stops; that's the cap working. Mint another to keep going. One key per agent keeps what it spent next to what it did.

## Packages

`@earntori/cli` · `@earntori/mcp` · `@earntori/sdk` — all on npm.

---

Built by BQ
