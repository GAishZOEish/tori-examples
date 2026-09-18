// Budgeted agent: an agent loop on OpenRouter using a Tori key with a hard spend cap.
// 1) npx @earntori/cli login   2) npx @earntori/cli key --limit 2 --write env   3) node --env-file=.env agent.mjs
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY, baseURL: process.env.OPENAI_BASE_URL ?? "https://openrouter.ai/api/v1" });
const model = process.env.MODEL ?? "openai/gpt-4o-mini";
const task = process.argv.slice(2).join(" ") || "Write a haiku about a budget that ran out.";

let steps = 0;
try {
  for (;;) {
    steps++;
    const r = await client.chat.completions.create({ model, messages: [{ role: "user", content: `${task}\n(step ${steps}; reply DONE when finished)` }] });
    const text = r.choices[0]?.message?.content ?? "";
    console.log(`[step ${steps}]`, text.trim());
    if (/\bDONE\b/.test(text) || steps >= 5) break;
  }
} catch (e) {
  // A spent or disabled Tori key returns 401 — that's the cap working, not a bug.
  if (e?.status === 401) console.log("Budget exhausted: the Tori key's cap is spent. Mint another with `npx @earntori/cli key --limit N`.");
  else throw e;
}
