#!/usr/bin/env bash
# Claude Code — Telegram Plugin Setup
# Implements the official setup from the Anthropic claude-plugins-official README.

set -euo pipefail

PLUGIN_ID="telegram@claude-plugins-official"

# ── helpers ──────────────────────────────────────────────────────────────────

info()    { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
ok()      { printf '\033[0;32m[ ok ]\033[0m  %s\n' "$*"; }
warn()    { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }
die()     { printf '\033[0;31m[err ]\033[0m  %s\n' "$*" >&2; exit 1; }

require() {
    command -v "$1" >/dev/null 2>&1 || die "'$1' not found — please install it first."
}

# ── pre-flight ────────────────────────────────────────────────────────────────

require claude
require bun    # the Telegram plugin runs on Bun

# ── step 1: bot token ─────────────────────────────────────────────────────────

if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    TOKEN="$TELEGRAM_BOT_TOKEN"
    info "Using TELEGRAM_BOT_TOKEN from environment."
else
    echo
    echo "Step 1 — Create a bot in @BotFather:"
    echo "  1. Open Telegram and start a chat with @BotFather"
    echo "  2. Send /newbot and follow the prompts"
    echo "  3. Copy the token it returns (looks like 123456:ABC-DEF...)"
    echo
    read -rp "Paste your bot token here: " TOKEN
    [[ -n "$TOKEN" ]] || die "Bot token cannot be empty."
fi

# ── step 2: install & configure plugin ───────────────────────────────────────

info "Installing plugin $PLUGIN_ID …"
claude "/plugin install $PLUGIN_ID"

info "Reloading plugins …"
claude "/reload-plugins"

info "Configuring bot token …"
claude "/telegram:configure $TOKEN"

# ── step 3: write launch script ───────────────────────────────────────────────

LAUNCH_SCRIPT="./start-telegram.sh"
cat > "$LAUNCH_SCRIPT" <<LAUNCH
#!/usr/bin/env bash
# Launch Claude Code with the Telegram channel enabled.
exec claude --channels "plugin:$PLUGIN_ID" "\$@"
LAUNCH
chmod +x "$LAUNCH_SCRIPT"
ok "Created $LAUNCH_SCRIPT"

# ── step 4: pairing instructions ──────────────────────────────────────────────

echo
echo "────────────────────────────────────────────────────────"
echo "Step 4 — Pair your Telegram account"
echo
echo "  1. Run:  $LAUNCH_SCRIPT"
echo "  2. DM your bot from Telegram — it will reply with a"
echo "     6-character pairing code."
echo "  3. Inside Claude Code run:"
echo "       /telegram:access pair <code>"
echo "  4. Lock down access to your account only:"
echo "       /telegram:access policy allowlist"
echo "────────────────────────────────────────────────────────"
echo
ok "Setup complete."
