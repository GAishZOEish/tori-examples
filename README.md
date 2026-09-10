# Tori Builder Beta — getting started

Tori is a rewards rail. Your app rewards your users; Tori handles the ledger, the claim, and the redemption — AI credits that work in Cursor, Claude Code, or any OpenAI-compatible tool within minutes. As a beta developer, **Tori rewards you with AI credits for building on it.** Everything below is live today; nothing is a preview.

Time to a working integration: ~15 minutes.

---

## 1. Sign in with GitHub
Go to **https://www.earntori.com/login** → **Continue with GitHub** → authorize.
GitHub is how the developer program knows it's you. If you already have a Tori account under the same email, signing in with GitHub links it.

## 2. Register your integration
Go to **https://www.earntori.com/developer** → fill in:
- Organization / app name
- What are you building? (one line)
- Kind of integration — an app that sends rewards · a widget where users redeem · an agent on a capped budget
- Repo or URL (optional)

Click **Create profile + first key**. **Copy the `tori_sk_…` key before you click "I've copied it"** — that button dismisses the panel; it doesn't copy. Lost it? Click *create a key* for a new one. Keep the key server-side; it never goes in client code.

## 3. Install the SDK
```bash
npm install @earntori/sdk
```

## 4. Wire Tori into your app
Decide what your users get rewarded for — a completed signup, a first project, a referral, a milestone — and call `issue()` from the server-side handler for that event:

```ts
import { Tori } from "@earntori/sdk";
const tori = new Tori({ apiKey: process.env.TORI_API_KEY! });

// inside your event handler, e.g. after a user publishes their first project
await tori.issue({
  externalUserId: user.id,               // your id for the user
  amountCents: 200,                      // what you're giving them (you fund your users' rewards)
  reason: "Published your first project",
  email: user.email,                     // they receive a claim email
  idempotencyKey: `first-project:${user.id}`,   // one key per event; retries are safe
});
```
One call per event, from your backend, with an idempotency key tied to the event. That's the whole integration. Read balances or history with `tori.balance(id)` and `tori.ledger(id)`.

## 5. How your users get rewarded
Here's what happens on their side:
1. They get an email from **your app's name**: "*<Your app> sent you $2.00 in AI credits*."
2. They click **Claim your credits** and sign in — that creates their Tori account if they don't have one.
3. The credits are already there. They can use them immediately in Tori's built-in chat (400+ models), or turn them into a spend-capped API key for Cursor, Claude Code, or any OpenAI-compatible tool — `npx @earntori/cli key --limit 5 --write env` drops it into their `.env`.

From your user's point of view: a reward from you, working AI in about two minutes, no card, no subscription. Nothing for you to build on that side — Tori owns the claim, the wallet, the chat, and the key.

## 6. How you get rewarded
Your integration earns AI credits as it reaches milestones through **real user activity** — your first API call, the first user your app rewards who signs in, the first redemption routed through your integration, and ongoing usage. Rewards land in your Tori balance automatically; amounts vary and may change during the beta.

Your own accounts, aliases, and test users don't count. Wire it into a real flow and let your users do the rest.

Check your numbers from the terminal:
```bash
npx @earntori/cli login      # GitHub device flow — enter the code it shows at github.com/login/device
npx @earntori/cli stats
```
And spend what you've earned in your own tools:
```bash
npx @earntori/cli key --limit 5 --write env
```

## 7. Optional: reward users your own way
If your users would rather have cash back, points, or a discount, issue with `rewardType: "EXTERNAL"`. Tori records it, attributes it to you, and (if you set a webhook URL at registration) POSTs a signed event. You deliver the reward through your own rail, then confirm:
```ts
await tori.issue({ externalUserId: "u1", amountCents: 300, reason: "Cash back", rewardType: "EXTERNAL", idempotencyKey: "rw_1" });
await tori.confirmReward("rw_1", { status: "PAID", reference: "payout_abc" });
```

## 8. Examples
Three runnable starters — https://github.com/GAishZOEish/tori-examples
- `sender-app` — reward a user on signup
- `rewards-widget` — your points → Tori credits at redemption
- `budgeted-agent` — an agent loop that stops when its Tori key's cap is spent

Full docs: **https://www.earntori.com/developers**

---

## What we need from you
- **Build the thing.** A real integration with real users is the whole point.
- **Tell us what broke or confused you** — first 10 minutes especially. Reply to the invite, or message Ben directly.
- **Tell us what you wanted and couldn't do.** Missing SDK method, wrong reward type, a tool the CLI should write to.

## Known limits (honest list)
- The CLI writes `.env` only; Cursor/Claude Code config writers aren't built — it prints the steps.
- Rewards to your users are AI credits (Tori-fulfilled) or EXTERNAL (you deliver). Gift cards and other Tori-fulfilled types aren't built yet.
- New integrations can issue up to $100 of credits before we raise the limit — ask.
- One integration per account for now.
