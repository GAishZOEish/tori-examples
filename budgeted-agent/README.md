# Budgeted agent
An agent that spends from a capped Tori key and stops when the cap is hit.

```
npm install
npx @earntori/cli login
npx @earntori/cli key --limit 2 --write env
node --env-file=.env agent.mjs "Summarize the three laws of thermodynamics"
```
The key returns 401 once its cap is spent — the budget is enforced by the rail, not the agent.
