#!/usr/bin/env bash

CONF_FILE="/etc/asterisk/tafreshiirancid.conf"

if [[ -f "$CONF_FILE" ]]; then
    source "$CONF_FILE"
else
    exit 0
fi

while read -r line; do
    [[ "$line" == "" ]] && break
done

CALLERID_NUM="${agi_callerid:-}"

normalize_number() {
    local num="$1"
    local province="$2"

    num="$(echo "$num" | tr -cd '0-9+')"

    if [[ "$num" =~ ^[0-9]{8}$ ]]; then
        echo "${province}${num}"
        return
    fi

    if [[ "$num" =~ ^0[0-9]{10}$ ]]; then
        echo "$num"
        return
    fi

    if [[ "$num" =~ ^98[0-9]{10}$ ]]; then
        echo "0${num:2}"
        return
    fi

    if [[ "$num" =~ ^\+98[0-9]{10}$ ]]; then
        echo "0${num:3}"
        return
    fi

    echo "$num"
}

NEW_CALLERID="$(normalize_number "$CALLERID_NUM" "$PROVINCE_CODE")"

if [[ -n "$NEW_CALLERID" && "$NEW_CALLERID" != "$CALLERID_NUM" ]]; then
    echo "SET VARIABLE CALLERID(num) \"$NEW_CALLERID\""
fi

exit 0
