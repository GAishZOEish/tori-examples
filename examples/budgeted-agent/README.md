# Budgeted agent

An agent loop on OpenRouter using a Tori key with a hard spend cap — and Tori's record of every call it makes.

```
npx @earntori/cli login
npx @earntori/cli key --limit 2 --write env
npm install
node --env-file=.env agent.mjs "Write a haiku about a budget that ran out."
```

What you'll see:

- `Tori head #N · open findings … · waived …` — the agent reads the record before acting
- one `[step n]` line per model call
- `Tori receipts` — two per step (an intent before the call, an outcome after it), each `seq:hash:sig`

Verify any receipt on your own machine: `npx @earntori/cli receipt <seq>`.

## What's on the record

For each model call the agent journals an **intent** (model, step, task length — never the task text) and, in a `finally`, an **outcome** (tokens used, or the failure). Both carry the same `action_id`, and the OpenRouter request carries it as an `X-Tori-Action` header so a later seam can record the same action. When the key's cap is spent the call fails with 401; the agent journals that too, then stops — that's the cap working.

These entries are self-reported (attestation level 0): Tori signs and orders what the agent said; it doesn't prove the call happened.

## Environment

`tori key --write env` writes `OPENAI_API_KEY`, `OPENAI_BASE_URL` and, when the repo is pinned to a Tori environment (`.tori/project.json`), `TORI_BASE_URL`. Without `TORI_BASE_URL` the SDK talks to production. Keys minted before `@earntori/cli` 0.2.5 can't act as agents — mint a fresh one.
