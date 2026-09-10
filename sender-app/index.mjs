// Sender app: your product rewards a user on signup.
// Run: TORI_API_KEY=tori_sk_... USER_EMAIL=someone@example.com node index.mjs
import { Tori } from "@earntori/sdk";

const tori = new Tori({ apiKey: process.env.TORI_API_KEY, baseUrl: process.env.TORI_BASE_URL ?? "https://www.earntori.com" });
const userId = process.env.USER_ID ?? `user_${Date.now()}`;

// Define a reward type named "signup_complete" on your developer page first.
// This runs inside your signup handler; Tori supplies the amount and handles duplicates.
const r = await tori.rewards.trigger({
  reward: "signup_complete",
  user: { id: userId, email: process.env.USER_EMAIL },   // email → claim email; omit for a shadow account
});
console.log("issued:", r.issued, "duplicate:", r.duplicate);
console.log("balance:", await tori.users.balance(userId));
