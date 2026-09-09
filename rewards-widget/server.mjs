// Rewards widget: a page where a user clicks "Redeem", and your server issues via the SDK.
// Your points ledger stays yours; Tori is the reward rail. Run: TORI_API_KEY=tori_sk_... node server.mjs
import { createServer } from "node:http";
import { Tori } from "@earntori/sdk";

const tori = new Tori({ apiKey: process.env.TORI_API_KEY, baseUrl: process.env.TORI_BASE_URL ?? "https://www.earntori.com" });
const points = new Map([["demo-user", 1200]]); // your own points ledger (1000 points = $1.00 here)

const page = `<!doctype html><meta charset=utf-8><title>Redeem</title>
<body style="font-family:system-ui;max-width:420px;margin:40px auto">
<h2>Your points: <span id=p></span></h2>
<label>Email for your AI credits <input id=e placeholder="you@example.com"></label>
<p><button id=b>Redeem 1,000 points for $1.00 of AI credits</button></p><pre id=o></pre>
<script>
const p=document.getElementById('p'),o=document.getElementById('o');
async function load(){p.textContent=(await (await fetch('/points')).json()).points}
document.getElementById('b').onclick=async()=>{const r=await fetch('/redeem',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:document.getElementById('e').value})});o.textContent=JSON.stringify(await r.json(),null,2);load()};load();
</script>`;

createServer(async (req, res) => {
  const json = (code, body) => { res.writeHead(code, { "content-type": "application/json" }); res.end(JSON.stringify(body)); };
  if (req.url === "/") { res.writeHead(200, { "content-type": "text/html" }); return res.end(page); }
  if (req.url === "/points") return json(200, { points: points.get("demo-user") });
  if (req.url === "/redeem" && req.method === "POST") {
    let raw = ""; for await (const c of req) raw += c;
    const { email } = JSON.parse(raw || "{}");
    const have = points.get("demo-user") ?? 0;
    if (have < 1000) return json(400, { error: "Not enough points" });
    const r = await tori.issue({ externalUserId: "demo-user", amountCents: 100, reason: "Redeemed 1,000 points", email: email || undefined });
    if (r.issued) points.set("demo-user", have - 1000);
    return json(200, r);
  }
  res.writeHead(404); res.end();
}).listen(3456, () => console.log("open http://localhost:3456"));
