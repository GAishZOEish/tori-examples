// Sender app: your product rewards a user on signup.
// Run: TORI_API_KEY=tori_sk_... USER_EMAIL=someone@example.com node index.mjs
import { Tori } from "@earntori/sdk";

const tori = new Tori({ apiKey: process.env.TORI_API_KEY, baseUrl: process.env.TORI_BASE_URL ?? "https://www.earntori.com" });
const userId = process.env.USER_ID ?? `user_${Date.now()}`;

// Define a reward type named "signup_complete" on your developer page first.
// This runs inside your signup handler. Tori supplies the amount and handles duplicates.
const user = { id: userId, email: process.env.USER_EMAIL };   // email → claim email; omit for a shadow account

// 1. Preview: eligible? what amount? nothing moves.
const check = await tori.rewards.preview({ reward: "signup_complete", user });
console.log("preview:", check.eligible, check.reason ?? "", check.amount_cents);
if (!check.eligible) process.exit(0);

// 2. Trigger the reward.
const r = await tori.rewards.trigger({ reward: "signup_complete", user });
console.log("issued:", r.issued, "duplicate:", r.duplicate, "amount_cents:", r.amount_cents);

// 3. Keep reward_id — it's the id for logs, support, and webhook correlation.
console.log("reward_id:", r.reward_id);
console.log("balance:", await tori.users.balance(userId));
