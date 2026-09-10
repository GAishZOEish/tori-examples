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

Click **Create profile + first key** → **Copy key** (the panel appears beside the button; Dismiss stays disabled until you've copied). Keep the key server-side; it never goes in client code.

## 3. Define your reward types
On the same page, in **Reward types**: name the thing you're rewarding, set the amount, choose once-per-user (activation-style) or once-per-event (referrals, per-project), save. For example: `first_project` · $2 · once per user.

Amounts live here, not in your code — a bug or a leaked key can only fire rewards you've configured, within limits Tori enforces.

## 4. Install the SDK and wire it in
```bash
npm install @earntori/sdk
```
Call `trigger()` from the server-side handler for the event you're rewarding:

```ts
import { Tori } from "@earntori/sdk";
const tori = new Tori({ apiKey: process.env.TORI_API_KEY! });

// inside your event handler, e.g. after a user publishes their first project
await tori.rewards.trigger({
  reward: "first_project",                          // the reward type you defined
  user: { id: user.id, email: user.email },         // email → they get a claim email
  eventId: project.id,                              // required for once-per-event rewards; ignored for once-per-user
});
```
That's the whole integration. Every response carries a `reward_id` — store it; it's the canonical identifier for logs, support, webhooks, and `confirm()` — plus the `amount_cents` Tori decided and `duplicate`. **Retries:** a duplicate `trigger()` returns the *original* `reward_id` and `amount_cents` with `duplicate: true`; nothing moves. Preview before you go live with `tori.rewards.preview({ reward, user })`: it returns `eligible`, `reason`, `amount_cents`, and remaining limits, and moves nothing. Errors are `ToriError`s with a `code` (`DUPLICATE_EVENT`, `LIMIT_EXCEEDED`, `REWARD_NOT_FOUND`, …).

Balances and history: `tori.users.balance(id)`, `tori.users.ledger(id)`. Advanced, dynamic amounts: `tori.rewards.issue({ externalUserId, amountCents, reason })` — prefer `trigger()`.

## 5. How your users get rewarded
Here's what happens on their side:
1. They get an email from **your app's name**: "*[Your app] sent you $2.00 in AI credits*."
2. They click **Claim your credits** and sign in — that creates their Tori account if they don't have one.
3. The credits are already there. They can use them immediately in Tori's built-in chat (400+ models), or turn them into a spend-capped API key for Cursor, Claude Code, or any OpenAI-compatible tool — `npx @earntori/cli key --limit 5 --write env` drops it into their `.env`.

From your user's point of view: a reward from you, working AI in about two minutes, no card, no subscription. Nothing for you to build on that side — Tori owns the claim, the wallet, the chat, and the key.

## 6. How you get rewarded
Your integration earns AI credits as it reaches milestones through **real user activity** — your first API call, the first new user your reward brings in who signs in, the first redemption routed through your integration, and ongoing usage. Rewards land in your Tori balance automatically; amounts vary and may change during the beta.

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
If your users would rather have cash back, points, or a discount, trigger with `rewardType: "EXTERNAL"`. Tori records it, attributes it to you, and (if you set a webhook URL on your developer page) POSTs a signed event you read with `tori.webhooks.parse()` — it verifies the signature and returns the event. Tori may deliver an event more than once on retry; dedupe on `event.data.reward_id`. `confirm()` is idempotent — repeating `PAID` for the same reward is acknowledged, not re-applied. You deliver the reward through your own rail, then confirm:
```ts
const r = await tori.rewards.trigger({ reward: "cash_back_10", user: { id: user.id }, eventId: order.id, rewardType: "EXTERNAL" });
await tori.rewards.confirm(r.reward_id, { status: "PAID", reference: "payout_abc" });
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
- One integration per account for now.
