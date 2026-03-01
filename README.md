# Validator Monitoring Suite

Production-minded monitoring framework for multi-network validator operations.

Maintained by **Xibz** — independent infrastructure operator focused on early-stage and VC-backed networks.

---

## Why

Node uptime alone is not enough.

This project focuses on:

- Early detection
- Operational discipline
- Consistent alerting
- Modular per-network checks

---

## Repository Structure

- `checks/` → project-specific checks
- `lib/` → shared modules (env loader + Discord alert sender)
- `config/` → configuration template
- `run/` → unified runner

---

## Networks Covered

- Republic — service + RPC + jailed detection (Cosmos SDK)
- Tempo — service + RPC
- Shelby — service + RPC

---

## How It Works

Each project file exposes one function:

- `republic_run_checks`
- `tempo_run_checks`
- `shelby_run_checks`

The unified runner `run/run_all.sh` loads all modules and executes them sequentially.

If any check fails, a Discord webhook alert is sent.

---

## Setup

### 1) Install dependencies

On your VPS:

- curl
- jq
- systemd (for systemctl)

---

### 2) Create local config (DO NOT COMMIT)

```bash
cp config/common.env.example config/common.env
nano config/common.env
```

Fill in:

- DISCORD_WEBHOOK_URL
- correct RPC URLs
- correct services
- (Republic) correct VALOPER + chain binary/id

`config/common.env` is ignored via `.gitignore`.

---

### 3) Make scripts executable

```bash
chmod +x lib/*.sh checks/*.sh run/*.sh
```

---

### 4) Run manually

```bash
CONFIG_FILE=./config/common.env ./run/run_all.sh
```

---

## Cron Example

Run every 5 minutes:

```bash
*/5 * * * * /bin/bash -lc 'cd ~/validator-monitoring-suite && CONFIG_FILE=./config/common.env ./run/run_all.sh'
```

---

## Security Notes

- Never commit webhook URLs.
- Never publish RPC endpoints or private infrastructure details.
- Keep configuration local.

---

## Disclaimer

Use at your own risk. Adapt checks and thresholds to your infrastructure.