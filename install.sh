#!/usr/bin/env bash

# مسیرهای اصلی
AGI_DIR="/var/lib/asterisk/agi-bin"
CONF_FILE="/etc/asterisk/tafreshiirancid.conf"
LOGIC_FILE="tafreshiirancid_logic.sh"
DIALPLAN_FILE="tafreshiirancid_dialplan.conf"
ASTERISK_CUSTOM_CONF="/etc/asterisk/extensions_custom.conf"

echo "--- Tafreshi Iran CID Installation ---"

# 1. پرسیدن کد استان
read -p "Enter Province Code (e.g., 021): " PROVINCE_CODE
if [[ -z "$PROVINCE_CODE" ]]; then
    PROVINCE_CODE="021"
    echo "Using default: 021"
fi

# 2. پرسیدن نام ترانک
read -p "Enter Inbound Trunk Name (Exactly as defined in Issabel): " TRUNK_NAME
if [[ -z "$TRUNK_NAME" ]]; then
    echo "Trunk name is required. Installation aborted."
    exit 1
fi

# 3. ساخت فایل تنظیمات
echo "PROVINCE_CODE=$PROVINCE_CODE" > "$CONF_FILE"
echo "TRUNK_NAME=$TRUNK_NAME" >> "$CONF_FILE"
echo "Config created at $CONF_FILE"

# 4. کپی کردن اسکریپت منطق به مسیر AGI و دادن مجوز
if [[ -f "$LOGIC_FILE" ]]; then
    cp "$LOGIC_FILE" "$AGI_DIR/"
    chmod +x "$AGI_DIR/$LOGIC_FILE"
    chown asterisk:asterisk "$AGI_DIR/$LOGIC_FILE"
    echo "Logic script installed to $AGI_DIR"
else
    echo "Error: $LOGIC_FILE not found in current directory!"
    exit 1
fi

# 5. اضافه کردن دیال‌پلن به extensions_custom.conf
# چک کردن اینکه آیا قبلاً این ماژول اضافه شده یا نه
if ! grep -q "custom-cid-normalization" "$ASTERISK_CUSTOM_CONF"; then
    echo "" >> "$ASTERISK_CUSTOM_CONF"
    cat "$DIALPLAN_FILE" >> "$ASTERISK_CUSTOM_CONF"
    echo "Dialplan added to $ASTERISK_CUSTOM_CONF"
else
    echo "Dialplan already exists in $ASTERISK_CUSTOM_CONF, skipping."
fi

# 6. ریلود کردن استریسک
echo "Reloading Asterisk Dialplan..."
asterisk -rx "dialplan reload"

echo "--------------------------------------"
echo "Installation Complete!"
echo "Now go to your Inbound Route for trunk [$TRUNK_NAME]"
echo "And set Context to: custom-cid-normalization"
echo "--------------------------------------"
