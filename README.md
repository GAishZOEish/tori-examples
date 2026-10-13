# Getting started

Tori holds your coding agents to a standard. Before an agent calls a task done, the work it hands back is checked against your coding standards and the standards your industry is held to; findings come with the fix, and the agent applies it. Everything the agent does is written to an append-only log with a signed receipt you can verify offline and show whoever needs proof; the agent reads that log at the start of every session.

Works with agents you use off the shelf — Claude Code, Cursor, Codex, Claude Cowork, Claude chat — and agents you build.

## Requirements

- Node 18 or later
- A GitHub account (sign-in)
- Checks cover JavaScript / TypeScript projects today

## Coding agents (CLI and IDE) — Claude Code, Codex, Cursor

```
cd your-project
npx @earntori/cli init
```

Signs you in with GitHub the first time (a link and a one-time code), then adds Tori's tools to Claude Code, Cursor and Codex for this project. In Claude Code and Codex the checks also run automatically when the agent stops, and the agent gets a one-line reminder at session start to read the log first. Restart the session (in Codex, run `/hooks` once to trust the two hooks). From then on:

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

When you add an agent you built, the first thing Tori does is check its code. Run `npx @earntori/cli init` in the agent's repo and the coding agent you build with gets the findings with their fixes, applies them, and can't finish with one open.

## Reading what your agents did

| Want to | Do |
| --- | --- |
| See a project's history | `npx @earntori/cli ledger` — newest first, one line per entry with its receipt; `--project all` for everything you own |
| See what this project is held to | `npx @earntori/cli standards` and `npx @earntori/cli rules` |
| Let an agent read it             | It calls `ledger_query`; with `include` it gets open findings, deferrals, recent runs and recent fixes                 |
| Verify one entry | `npx @earntori/cli receipt <seq>` — checks the entry against Tori's published key and prints `VERIFIED` |
| Follow one action                | `ledger_query { action_id }` — the intent, any findings on it, and its outcome                                        |

## Packages

`@earntori/cli` · `@earntori/mcp` — both on npm.

---

Built by BQ
