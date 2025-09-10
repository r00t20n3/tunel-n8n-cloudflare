<div align="center">

# Cloudflare Tunnel Manager (Bash Only) – Optimized for n8n Self‑Hosters

Securely expose your local **n8n** (and other services) to the internet with zero port forwarding.

Three lightweight Bash scripts + Cloudflare Tunnel = inbound webhooks, OAuth callbacks, and integrations that “just work”.

[Repo](https://github.com/r00t20n3/tunel-n8n-cloudflare) · Author: **Frank I.** · [LinkedIn](https://www.linkedin.com/in/frankrevops)

</div>

---

## 🔥 What Is This? (n8n Context)
If you self‑host **n8n** behind a home router or on a lab machine (macOS / Linux / Termux) you typically need:
* A stable public URL for webhooks (`/webhook/*` and `/webhook-test/*`).
* SSL without managing certs.
* A way to receive OAuth 2.0 redirect callbacks (Google, Notion, Slack, etc.).

Cloudflare Tunnels solve this by creating an outbound, persistent, TLS-secured connection—no firewall or NAT fiddling. This repo gives you a **multi‑domain, menu‑driven tunnel + DNS manager** with optional CLI automation.

Scripts:
* `cfinstaller.sh` – installs `cloudflared` (official Cloudflare client).
* `cfmanager.sh` – create / start / stop / export tunnels; multi‑domain aware.
* `cfdns.sh` – DNS record helper (auto‑called on tunnel creation; usable standalone).

No database, no Go binaries, no heavy dependencies—**pure Bash**.

---

## ✨ Key Features (n8n‑Relevant)
| Capability | Why n8n Users Care |
|------------|--------------------|
| Multi-domain support | Separate staging vs prod (e.g. dev.example.com, flows.example.net) |
| Random subdomain generator | Quick temporary webhook endpoints for testing |
| Automatic DNS CNAME creation | No manual dashboard work when provisioning a new webhook URL |
| Background process + PID tracking | Keep tunnel alive while you iterate in n8n UI |
| Per‑tunnel logs | Diagnose webhook timeouts or 502s quickly |
| Export tunnel bundle | Move n8n + tunnel to another box or VPS easily |
| CLI non‑interactive mode | Integrate with cron / provisioning scripts |
| Zero port exposure | Avoid opening 5678 (or custom port) to the public internet |

Extra benefits:
* Works with n8n test webhooks (“listen mode”).
* Consistent HTTPS base URL helps with OAuth credential setup.
* Can dedicate a subdomain per workflow family (e.g. `crm.example.com`, `ai.example.com`).

---

## ✅ Requirements
* Cloudflare account (free plan works)
* Domain added to Cloudflare (nameservers pointing there)
* API Token (DNS Edit scope for the zone)
* `cloudflared` (installer handles it)
* Local n8n running (default: `http://localhost:5678`)

Optional / nice‑to‑have:
* Termux on Android (mobile ops)
* `dig` or `nslookup` for DNS checks
* Cloudflare Access (Zero Trust) if you later want auth gating

---

## 🛠 Install
```bash
git clone https://github.com/r00t20n3/tunel-n8n-cloudflare.git
cd tunel-n8n-cloudflare
bash cfinstaller.sh
```
This installs `cloudflared` and prepares directories:
```
~/.cloudflared/
   domains/         # per-domain config files
   pids/            # runtime PID files
   <tunnel>-*.log   # logs
```

---

## 🔑 Get Cloudflare Credentials
1. Zone ID: Dashboard → Select domain → Overview panel (right sidebar)
2. API Token: Profile → API Tokens → Create Token → Template: “Edit zone DNS” → Scope: your zone → Create → Copy token

You’ll supply these once per domain inside the manager.

---

## ➕ Add a Domain
```bash
bash cfmanager.sh
```
Menu → Manage Domains → Add new domain → enter:
- Domain (example.com)
- API Token
- Zone ID

Creates: `~/.cloudflared/domains/example.com.conf`.

If an old `.env` exists with CF_* vars it will auto‑migrate to this format and rename to `.env.migrated`.

---

## 🚇 Create a Tunnel for n8n (Port 5678 Default)
Manager path: Manage Tunnels → Select domain → Create new tunnel

Prompts explained:
* Subdomain: choose `n8n` (or leave blank for random) → becomes public host.
* Local port: `5678` (or your custom `N8N_PORT`).
* Auto-create DNS: yes (`y`) to publish immediately.
* Start now: yes (`y`) to launch the daemon.

After creation you’ll have: `https://n8n.example.com` (or random). Use this as your `WEBHOOK_URL` base if you override n8n defaults.

Tip: In n8n, set `N8N_HOST` to the chosen subdomain and `N8N_PROTOCOL=https` for nicer self-referential links (optional; n8n works even if you don’t modify these).

---

## 🧪 Non-Interactive Usage
From scripts / cron / CI:
```bash
./cfmanager.sh create --sub api --port 3000
./cfmanager.sh start api
./cfmanager.sh stop api
./cfmanager.sh export api
```
Note: For multi-domain automation set env vars first or run interactively once to create domain config. (Future enhancement: flags for selecting domain.)

---

## 📂 Files Generated Per Tunnel
Location: `~/.cloudflared/`
- `<name>-config.yml` – tunnel config (ingress rules)
- `<tunnel-id>.json` – credentials (do not share publicly)
- `pids/<name>.pid` – background process tracking
- `<name>-tunnel.log` – runtime log (view via dashboard logs command)

---

## � Export & Move a Tunnel
In status dashboard: `export <name>`
Creates: `./cloudflared-export/<name>/` with config + creds.
On new host: place under `~/.cloudflared/`, adjust `credentials-file` path if needed, then start.

---

## 🧹 Delete a Tunnel
Dashboard: `delete <name>`
- Stops process (if running)
- Removes local config, creds, log, pid
- Deletes associated DNS CNAME (if exists)
- Removes the Cloudflare tunnel itself

---

## 🛡 Security Notes
- API Token scope: prefer per‑zone DNS Edit only
- Credentials JSON = secret; treat like a password
- Rotate API token if compromised (`~/.cloudflared/domains/<domain>.conf` update token)
- Avoid embedding tokens in shell history; paste carefully

---

## 🩺 Troubleshooting
| Symptom | Check |
|---------|-------|
| Tunnel shows STOPPED | Log file `~/.cloudflared/<name>-tunnel.log` for errors |
| DNS not resolving | Confirm CNAME in Cloudflare dashboard & propagation (dig) |
| Port unreachable | Service actually listening on 0.0.0.0? Adjust app bind address |
| Random exit on macOS | Logs: maybe permission / code signing → reinstall `cloudflared` |
| Delete fails | Was tunnel name correct? Script uses `<sub>-tunnel` internally |

Useful commands:
```bash
cloudflared tunnel list
dig +short example.app.n8n.cloud
tail -f ~/.cloudflared/n8n-tunnel.log
```

---

## 🧰 Example Services
| Service | Local Port | Example Public URL |
|---------|------------|--------------------|
| n8n | 5678 | https://n8n.example.com |
| Home Assistant | 8123 | https://ha.example.com |
| Node API | 3000 | https://api.example.com |
| Dev React App | 5173 | https://app.example.com |

---

## 🔁 Updating cloudflared
Re-run installer:
```bash
bash cfinstaller.sh
```
(macOS Homebrew users may prefer `brew upgrade cloudflare/cloudflare/cloudflared`.)

---

## 🧭 Roadmap (Ideas)
- Domain flag for non-interactive operations (e.g. `--domain example.com`)
- Bulk tunnel creation from a spec file
- Health probes & auto-restart watchdog

PRs / issues welcome.

---

## 👤 Author
**Frank I.**  
LinkedIn: https://www.linkedin.com/in/frankrevops

---

## � License
Do whatever you want!

---

## ✅ Quick Start (Copy/Paste)
```bash
git clone https://github.com/r00t20n3/tunel-n8n-cloudflare.git \
   && cd tunel-n8n-cloudflare \
   && bash cfinstaller.sh \
   && bash cfmanager.sh
```

Enjoy secure zero‑config exposure of your local tools.

---

## ❓ Support
Open an issue in the repo if you hit bugs or have feature requests.

---

Happy tunneling!
