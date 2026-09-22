---
description: Put this agent's actions on Tori's record — journal an intent before each consequential action, an outcome after it, read the ledger first, print receipts.
argument-hint: [path to the agent's entry file, optional]
---

You are adding Tori's accountability calls to an existing agent in this repository. Tori keeps a signed, append-only journal; the agent records what it is about to do and what happened, gets a receipt for each entry, and can read the record before it acts. Entries are self-reported (attestation level 0) — say so in comments; never claim the record proves an action happened, only that the agent said so and Tori signed and ordered the saying.

Target: $ARGUMENTS (if empty, find the agent's entry point yourself — the file with the main loop or the top-level run function).

## 1. Check the ground first
- Run `ledger_query` (the Tori MCP tool) with include `open_findings, waived, head` for this project before changing anything. If the tool is missing, Tori is not installed here: stop and tell the developer to run `npx @earntori/cli init`, then restart the session.
- Read the `tori-sdk` skill for the exact API before writing code.

## 2. Find the decision points
Read the agent and list, in your reply, every place it does one of these:
- moves or commits money, credits, or inventory
- writes to an external system (CRM, ledger, database of record, file share, repo, calendar)
- sends anything a person will receive (email, message, ticket, notification)
- deletes or overwrites
- calls a paid API (including every model call in a paid loop)
- waits for a human decision (approval gate, "are you sure", a queue it pushes to)

Each of those is a decision point. Anything else (parsing, formatting, reading) is not.

## 3. Wire the calls
Choose the client:
- JavaScript/TypeScript agent → `@earntori/sdk` ≥ 0.3.0 in agent mode: `new Tori({ apiKey: process.env.OPENAI_API_KEY })` — the capped key from `npx @earntori/cli key --write env` is the agent's Tori credential. Add `baseUrl: process.env.TORI_BASE_URL` when the developer works against a non-production Tori.
- Any other language → the HTTP calls in the skill (three endpoints, bearer = the same key). Do not invent an SDK.

Then, keeping the agent's behaviour unchanged:
- At start: `ledger.query({ include: ["open_findings", "waived", "rewards", "head"] })` (or the HTTP equivalent) and print a two-line summary — head seq and anything open or waived.
- Before each decision point: `journal.intent({ summary, ref?, payload? })` → keep the returned `action_id`. `summary` is one factual sentence with the concrete object (invoice id, recipient, amount). `ref` is the object acted on when there is one (`{ type: "invoice", id: "INV-42" }`).
- After it: `journal.outcome({ action_id, summary, payload? })` — what actually happened, including "nothing" and failures. Wrap the action in try/finally so the outcome is always written; on error, the summary says it failed and why.
- If the action makes an HTTP call to another service, add `journal.headers(action_id)` (an `X-Tori-Action` header) to that request so a downstream seam can record the same action.
- At a human gate: `journal.note({ action_id, summary: "held for approval: …" })` when it pauses, then the `outcome` when the decision arrives. (Tori's `action.held` / `action.approved` events are reserved for a later phase; use `note` + `outcome` now.)
- At the end: print the receipts for the entries written in this run (`receipt.short` from each call), one per line, so the developer can paste any into `tori receipt <seq>`.

Rules:
- Never put file contents, secrets, tokens, or full request bodies in a summary or payload. Ids, amounts, counts, statuses, and hashes are fine.
- Keep payloads under 8 KB and summaries under 500 characters.
- Do not journal reads (querying, listing, fetching) — only actions.
- One intent per decision point, one outcome per intent. Do not batch several actions under one action_id.
- Do not change what the agent does. If you must restructure to reach a decision point, keep the change minimal and say what you changed.

## 4. Verify and report
- Run the agent once in a dry or sandbox mode if it has one. Confirm each decision point produced an intent and an outcome with the same `action_id`, and that the final receipt list prints.
- Call `ledger_query` again with `limit 20` and confirm the new `action.intent` / `action.outcome` pairs appear with receipts.
- In your reply: the list of decision points you found, the calls you added (file:line), the receipts from the verification run, and anything you could not wire (with the reason). Do not claim a decision point is covered unless you saw its intent and outcome on the ledger.
