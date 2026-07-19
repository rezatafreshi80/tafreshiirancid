#!/usr/bin/env bash

set -e

APP_NAME="tafreshiirancid"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
AGI_SOURCE="$BASE_DIR/tafreshiirancid_logic.sh"
AGI_TARGET="/var/lib/asterisk/agi-bin/tafreshiirancid_logic.sh"
CONF_DIR="/etc/asterisk"
APP_CONF="$CONF_DIR/${APP_NAME}.conf"
CUSTOM_CONF="$CONF_DIR/extensions_custom.conf"
BACKUP_DIR="$BASE_DIR/backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "   Tafreshi Iran CID Installer"
echo "=========================================="

if [[ $EUID -ne 0 ]]; then
    echo "Error: installer must be run as root."
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo
read -rp "Enter province code (example: 021): " PROVINCE_CODE
PROVINCE_CODE="${PROVINCE_CODE// /}"

if [[ -z "$PROVINCE_CODE" ]]; then
    echo "Error: province code cannot be empty."
    exit 1
fi

if ! [[ "$PROVINCE_CODE" =~ ^0[0-9]{2,3}$ ]]; then
    echo "Error: province code format is invalid. Example: 021 or 026"
    exit 1
fi

echo
read -rp "Enter inbound trunk name exactly as in Issabel/Asterisk: " TRUNK_NAME
TRUNK_NAME="${TRUNK_NAME// /}"

if [[ -z "$TRUNK_NAME" ]]; then
    echo "Error: trunk name cannot be empty."
    exit 1
fi

if [[ ! -f "$AGI_SOURCE" ]]; then
    echo "Error: file not found: $AGI_SOURCE"
    exit 1
fi

echo
echo "[1/6] Creating config file..."
cat > "$APP_CONF" <<EOF
PROVINCE_CODE="$PROVINCE_CODE"
TRUNK_NAME="$TRUNK_NAME"
EOF

cp "$APP_CONF" "$BACKUP_DIR/" 2>/dev/null || true
chmod 640 "$APP_CONF"
chown asterisk:asterisk "$APP_CONF" 2>/dev/null || true

echo "[2/6] Installing AGI script..."
cp "$AGI_SOURCE" "$AGI_TARGET"
chmod +x "$AGI_TARGET"
chown asterisk:asterisk "$AGI_TARGET" 2>/dev/null || true

echo "[3/6] Backing up custom dialplan..."
if [[ -f "$CUSTOM_CONF" ]]; then
    cp "$CUSTOM_CONF" "$BACKUP_DIR/" 2>/dev/null || true
else
    touch "$CUSTOM_CONF"
fi

echo "[4/6] Injecting auto-generated dialplan..."
sed -i '/;--- TAFRESHIIRANCID START ---/,/;--- TAFRESHIIRANCID END ---/d' "$CUSTOM_CONF"

cat >> "$CUSTOM_CONF" <<'EOF'

;--- TAFRESHIIRANCID START ---
[from-trunk-custom]
exten => _.,1,NoOp(*** Tafreshi Iran CID Normalize *** )
 same => n,AGI(tafreshiirancid_logic.sh)
 same => n,Goto(from-trunk,${EXTEN},1)

; Hook for all inbound trunks
[from-trunk]
exten => _X.,1,Goto(from-trunk-custom,${EXTEN},1)
;--- TAFRESHIIRANCID END ---
EOF

echo "[5/6] Validating Asterisk configuration..."
asterisk -rx "dialplan reload" >/dev/null 2>&1 || {
    echo "Error: dialplan reload failed."
    echo "Check Asterisk configuration manually."
    exit 1
}

echo "[6/6] Done."

echo
echo "=========================================="
echo " Installation completed successfully"
echo " Province Code : $PROVINCE_CODE"
echo " Trunk Name    : $TRUNK_NAME"
echo " Config File   : $APP_CONF"
echo " AGI Script    : $AGI_TARGET"
echo " Backup Folder : $BACKUP_DIR"
echo "=========================================="
