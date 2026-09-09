// Sender app: your product rewards a user on signup.
// Run: TORI_API_KEY=tori_sk_... USER_EMAIL=someone@example.com node index.mjs
import { Tori } from "@earntori/sdk";

const tori = new Tori({ apiKey: process.env.TORI_API_KEY, baseUrl: process.env.TORI_BASE_URL ?? "https://www.earntori.com" });
const userId = process.env.USER_ID ?? `user_${Date.now()}`;

// Pretend this runs inside your signup handler.
const r = await tori.issue({
  externalUserId: userId,
  amountCents: 500,
  reason: "Welcome to our app — here's $5 of AI credits",
  email: process.env.USER_EMAIL,           // omit to issue without a claim email
  idempotencyKey: `signup:${userId}`,      // safe to retry
});
console.log("issued:", r.issued, "duplicate:", r.duplicate, "idempotencyKey:", r.idempotencyKey);
console.log("balance:", await tori.balance(userId));
