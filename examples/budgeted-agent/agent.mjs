// Budgeted agent: an agent loop on OpenRouter using a Tori key with a hard spend cap — and Tori's record of every call.
// 1) npx @earntori/cli login   2) npx @earntori/cli key --limit 2 --write env   3) node --env-file=.env agent.mjs
//
// The capped key is also the agent's Tori credential (agent mode). Journal entries are self-reported
// (attestation level 0): Tori signs and orders what this agent says it did; it does not prove the call happened.
import OpenAI from "openai";
import Tori from "@earntori/sdk";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY, baseURL: process.env.OPENAI_BASE_URL ?? "https://openrouter.ai/api/v1" });
const tori = new Tori({ apiKey: process.env.OPENAI_API_KEY, baseUrl: process.env.TORI_BASE_URL }); // project defaults to this repo
const model = process.env.MODEL ?? "openai/gpt-4o-mini";
const task = process.argv.slice(2).join(" ") || "Write a haiku about a budget that ran out.";
const receipts = [];

// Read the record before acting.
const before = await tori.ledgerQuery({ include: ["open_findings", "waived", "rewards", "head"] });
console.log(`Tori head #${before.head?.seq ?? "?"} · open findings ${before.open_findings?.length ?? 0} · waived ${before.waived?.length ?? 0}`);

let steps = 0;
try {
  for (;;) {
    steps++;
    // Decision point: every model call spends from the capped key.
    const intent = await tori.journal.intent({
      summary: `Call ${model} for step ${steps} of the task (paid, capped key)`,
      ref: { type: "model_call", id: `step-${steps}` },
      payload: { model, step: steps, task_chars: task.length },
    });
    receipts.push(intent.receipt.short);
    let r, error;
    try {
      r = await client.chat.completions.create(
        { model, messages: [{ role: "user", content: `${task}\n(step ${steps}; reply DONE when finished)` }] },
        { headers: tori.journal.headers(intent.action_id) }, // the same action, visible to the next seam
      );
    } catch (e) {
      error = e;
    } finally {
      const outcome = await tori.journal.outcome(error
        ? { action_id: intent.action_id, summary: `Model call for step ${steps} failed: ${error.status === 401 ? "401 — key cap spent or key disabled" : String(error.message).slice(0, 200)}`, payload: { status: error.status ?? null, error: error.name } }
        : { action_id: intent.action_id, summary: `Model call for step ${steps} returned ${r.usage?.total_tokens ?? "?"} tokens`, payload: { id: r.id, finish_reason: r.choices[0]?.finish_reason ?? null, usage: r.usage ?? null } });
      receipts.push(outcome.receipt.short);
    }
    if (error) throw error;
    const text = r.choices[0]?.message?.content ?? "";
    console.log(`[step ${steps}]`, text.trim());
    if (/\bDONE\b/.test(text) || steps >= 5) break;
  }
} catch (e) {
  // A spent or disabled Tori key returns 401 — that's the cap working, not a bug.
  if (e?.status === 401) console.log("Budget exhausted: the Tori key's cap is spent. Mint another with `npx @earntori/cli key --limit N`.");
  else throw e;
} finally {
  console.log("Tori receipts (verify any with `npx @earntori/cli receipt <seq>`):");
  for (const short of receipts) console.log("  " + short);
}
