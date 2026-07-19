#!/bin/bash

CONFIG_FILE="/etc/asterisk/tafreshi_cid.conf"

# Read province code from config file
if [ -f "$CONFIG_FILE" ]; then
    PROVINCE_CODE="$(cat "$CONFIG_FILE" | tr -d '[:space:]')"
else
    PROVINCE_CODE="021"
fi

# Asterisk passes CallerID as the first argument
RAW_CID="$1"

# Keep digits only
CID="$(echo "$RAW_CID" | sed 's/[^0-9]//g')"

FINAL_CID="$CID"

# If it's an 8-digit local number, prefix province code
if [[ "$CID" =~ ^[1-9][0-9]{7}$ ]]; then
    FINAL_CID="${PROVINCE_CODE}${CID}"
fi

# Send result back to Asterisk AGI
echo "SET VARIABLE CALLERID(num) ${FINAL_CID}"
exit 0
