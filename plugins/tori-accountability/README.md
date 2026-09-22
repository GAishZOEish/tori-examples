# tori-accountability (Claude Code plugin)

`/tori-accountability:add-tori-accountability [entry file]` (Claude Code namespaces plugin commands by plugin name) — scaffolds Tori's journal calls into an existing agent: `ledger_query` at start, `intent` before each consequential action, `outcome` after it (including failures), `X-Tori-Action` on downstream calls, receipts printed at the end. Ships with a `tori-sdk` skill (agent-mode reference: SDK, raw HTTP, MCP tools).

Install (marketplace pattern):

```
/plugin marketplace add GAishZOEish/tori-examples
/plugin install tori-accountability@tori
```

Prerequisite in the target repo: `npx @earntori/cli init` (the plugin does not register the MCP server or hooks itself — `tori init` owns that).

Entries written this way are self-reported (attestation level 0): Tori signs and orders what the agent said; it does not observe the action. Docs: https://www.usetori.dev
