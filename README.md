# Tori Builder Beta — getting started

Tori is a rewards rail. Your app rewards your users; Tori handles the ledger, the claim, and the redemption — AI credits that work in Cursor, Claude Code, or any OpenAI-compatible tool within minutes. As a beta developer, **Tori rewards you with AI credits for building on it.** Everything below is live today; nothing is a preview.

Time to first reward: ~15 minutes.

---

## 1. Sign in with GitHub
Go to **https://www.earntori.com/login** → **Continue with GitHub** → authorize.
GitHub is how the developer program knows it's you (account age is one of the fraud checks). If you already have a Tori account under the same email, signing in with GitHub links it.

## 2. Register your integration (30 seconds, no approval)
Go to **https://www.earntori.com/developer** → fill in:
- Organization / app name
- What are you building? (one line)
- Kind of integration — an app that sends rewards · a widget where users redeem · an agent on a capped budget
- Repo or URL (optional)

Click **Create profile + first key**. **Copy the `tori_sk_…` key before you click "I've copied it"** — that button dismisses the panel; it doesn't copy. Lost it? Click *create a key* for a new one.

## 3. Install the SDK
```bash
npm install @earntori/sdk
```

## 4. Issue your first reward
```ts
import { Tori } from "@earntori/sdk";
const tori = new Tori({ apiKey: process.env.TORI_API_KEY! });

await tori.issue({
  externalUserId: "user_123",      // your id for the user
  amountCents: 200,                // $2.00 — you fund what your users receive
  reason: "Welcome bonus",
  email: "them@example.com",       // they get a claim email; signing in creates their account
});
```
Expected response: `{ issued: true, duplicate: false, notified: true, ... }`.
Retries are safe — pass your own `idempotencyKey` or use the one the SDK returns.

Try it on yourself first: use an email you control (a Gmail `+alias` works) and claim it in a private window.

## 5. Watch the loop reward you
The moment your first API call lands, your Tori balance shows a **starter reward**. When the user you rewarded signs in for the first time, you're rewarded again; when they mint a key, again. All automatic.

Check it from the terminal:
```bash
npx @earntori/cli login      # GitHub device flow — enter the code it shows at github.com/login/device
npx @earntori/cli stats
```
You'll see rewards issued, users reached, claimed, redemptions routed, and **credits earned**, with the three milestones ticked as they happen.

## 6. Use your credits in your tools
```bash
npx @earntori/cli key --limit 5 --write env
```
Mints a $5 spend-capped key and appends `OPENAI_API_KEY` + `OPENAI_BASE_URL` to `.env`. It works anywhere the OpenAI API works (base URL `https://openrouter.ai/api/v1`, 400+ models) and stops with a 401 when the cap is spent. For Cursor: Settings → Models → OpenAI key + override base URL. For Claude Code and most others: the two env vars.

## 7. Optional: reward users your own way
If your users want cash back, points, or a discount instead of AI credits, issue with `rewardType: "EXTERNAL"`. Tori records it, attributes it to you, and (if you set a webhook URL at registration) POSTs a signed event. You deliver the reward through your own rail, then confirm:
```ts
await tori.issue({ externalUserId: "u1", amountCents: 300, reason: "Cash back", rewardType: "EXTERNAL", idempotencyKey: "rw_1" });
await tori.confirmReward("rw_1", { status: "PAID", reference: "payout_abc" });
```

## 8. Examples
Three runnable starters in the repo — https://github.com/GAishZOEish/tori-examples
- `sender-app` — reward a user on signup
- `rewards-widget` — your points → Tori credits at redemption
- `budgeted-agent` — an agent loop that stops when its Tori key's cap is spent

Full docs: **https://www.earntori.com/developers**

---

## What the program rewards (beta rates)
| Event | Reward |
|---|---|
| Starter — your first API call from a registered integration | $2.50 |
| First reward your app issues that a user claims (one-time) | $5.00 |
| First redemption routed through your integration (one-time) | $5.00 |

Guardrails: GitHub account at least 6 months old; $50/developer/month cap; 3 rewarded events/day/integration. Credits go to your Tori balance — spend them with `tori key`.

## What we need from you
- **Build the thing.** A real integration with real users is the whole point.
- **Tell us what broke or confused you** — first 10 minutes especially. Reply to the invite, or message Ben directly.
- **Tell us what you wanted and couldn't do.** Missing SDK method, wrong reward type, a tool the CLI should write to.

## Known limits (honest list)
- The CLI writes `.env` only; Cursor/Claude Code config writers aren't built — it prints the steps.
- Rewards to your users are AI credits (Tori-fulfilled) or EXTERNAL (you deliver). Gift cards and other Tori-fulfilled types aren't built yet.
- New integrations can issue up to $100 of credits before we raise the limit — ask.
- One integration per account for now.
