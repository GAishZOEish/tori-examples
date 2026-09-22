---
name: tori-sdk
description: Reference for Tori's agent-mode calls — journal intent/outcome/note with action_id, ledger query, receipts — via @earntori/sdk, raw HTTP, or the Tori MCP tools. Use when adding or reviewing Tori accountability calls in an agent.
---

# Tori — agent-mode reference

Tori's journal is append-only and hash-chained; every entry gets an Ed25519-signed receipt. Agent entries are **self-reported (attestation level 0)**: the record proves Tori signed and ordered what the agent said, not that the action happened. Say that in code comments and docs.

## Credential
The agent's Tori credential is its capped key (an `sk-or-…` key minted by `npx @earntori/cli key --limit N --write env`). It is both the model key (OpenRouter-compatible) and the bearer for Tori's agent endpoints. One `agents` row is created per key (harness `sdk`), so every entry is attributed to that key's agent and the developer who minted it. Keys minted before Tori 0.2.5 cannot act as agents — mint a fresh one.

## @earntori/sdk ≥ 0.3.0 (JavaScript / TypeScript)
```js
import Tori from "@earntori/sdk";
const tori = new Tori({ apiKey: process.env.OPENAI_API_KEY, baseUrl: process.env.TORI_BASE_URL }); // agent mode

const before = await tori.ledgerQuery({ include: ["open_findings", "waived", "rewards", "head"] });
console.log(`Tori head #${before.head?.seq}; open findings: ${before.open_findings?.length ?? 0}`);

const { action_id, receipt } = await tori.journal.intent({
  summary: "Post invoice INV-42 ($1,240.00) to the AP ledger",
  ref: { type: "invoice", id: "INV-42" },
  payload: { amount_cents: 124000, vendor_id: "V-9" },
});
let result;
try {
  result = await fetch("https://ledger.example/entries", { method: "POST", headers: { ...tori.journal.headers(action_id), "Content-Type": "application/json" }, body: JSON.stringify(entry) });
  await tori.journal.outcome({ action_id, summary: `Posted INV-42; ledger entry ${result.id}`, payload: { status: result.status } });
} catch (e) {
  await tori.journal.outcome({ action_id, summary: `Failed to post INV-42: ${e.message}`, payload: { error: e.name } });
  throw e;
}
console.log(`Receipt: ${receipt.short}`);

// Human gate
await tori.journal.note({ action_id, summary: "held for approval: refund over $500" });
// … later, when the decision arrives:
await tori.journal.outcome({ action_id, summary: "Approved by ops@…; refund issued" });

// Prove an entry (recomputes the hash and checks the signature locally)
const r = await tori.receipt(receipt.seq, { verify: true }); // r.verdict === "VERIFIED"
```
Notes: `intent` returns `{ action_id, kind, receipt }` where `receipt = { event_id, seq, hash, prev_hash, sig, short }`. `ledgerQuery` also accepts `project`, `event_type`, `since`, `until`, `ref_id`, `action_id`, `limit`, `before_seq`. Partner mode (`tori_sk_` keys, rewards to your users) is a different client and unchanged.

## Raw HTTP (any language)
Base `https://www.earntori.com` (or the developer's `TORI_BASE_URL`). Header `Authorization: Bearer <capped key>`, `Content-Type: application/json`.
- `POST /api/v1/journal/append` body `{ "kind": "intent"|"outcome"|"note", "summary": "...", "action_id"?: "<uuid>", "ref"?: {"type","id"}, "payload"?: {...}, "project"?: "..." }` → `201 { action_id, kind, receipt }`. `intent` mints `action_id`; `outcome` and `note` require it.
- `GET /api/v1/ledger/query?include=open_findings,waived,rewards,head&limit=50` (plus the filters above) → `{ ...sections, events: [...], next_before_seq }`.
- `GET /api/v1/ledger/receipts/{event_id|seq}` → the receipt with its preimage; `GET /api/v1/ledger/receipt-key` → the public key to verify `sig` over `"${seq}|${hash}"` (Ed25519, base64 SPKI).
Limits: summary ≤ 500 chars, payload ≤ 8 KB, 120 entries/minute per agent.

## Tori MCP tools (Claude Code, Cursor, Cowork, any MCP harness)
Same three operations as tools: `journal_append { kind, summary, action_id?, payload?, ref?, project? }`, `ledger_query { include?, ... }`, `receipt { id }`. Claude Code and Cursor get them from `npx @earntori/cli init`; a remote harness (Claude Cowork, claude.ai) gets them by adding the connector URL from `npx @earntori/cli connector new`.

## What to journal
Actions only — money moved, external writes, messages sent, deletions, paid API calls, human gates. Never reads. Never file contents, secrets, tokens, or full request bodies; ids, amounts, counts, statuses, hashes are fine. One intent per decision point, one outcome per intent, `X-Tori-Action` on downstream calls so a second seam can record the same action.
