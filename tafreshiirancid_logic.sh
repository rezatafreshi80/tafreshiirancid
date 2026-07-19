#!/usr/bin/env bash

CONFIG_FILE="/etc/asterisk/tafreshiirancid.conf"

read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        PROVINCE_CODE="$(grep -E '^PROVINCE_CODE=' "$CONFIG_FILE" | head -n1 | cut -d= -f2- | tr -d '[:space:]')"
    fi

    [[ -z "$PROVINCE_CODE" ]] && PROVINCE_CODE="021"
}

agi_read_env() {
    while IFS= read -r line; do
        [[ -z "$line" ]] && break
    done
}

agi_cmd() {
    local cmd="$1"
    local reply

    printf '%s\n' "$cmd"
    IFS= read -r reply || return 1
    printf '%s\n' "$reply"
}

get_agi_variable() {
    local varname="$1"
    local reply value

    reply="$(agi_cmd "GET VARIABLE ${varname}")" || return 1
    value="$(awk -F'[()]' '/^200 result=1/ {print $2}' <<< "$reply")"
    printf '%s' "$value"
}

set_agi_variable() {
    local varname="$1"
    local value="$2"

    agi_cmd "SET VARIABLE ${varname} ${value}" >/dev/null
}

normalize_callerid() {
    local raw_cid digits final_cid

    raw_cid="$(get_agi_variable "CALLERID(num)")"
    digits="$(printf '%s' "$raw_cid" | tr -cd '0-9')"

    final_cid="$digits"

    # If it looks like a local number, prefix province code
    if [[ "$digits" =~ ^[1-9][0-9]{7}$ ]]; then
        final_cid="${PROVINCE_CODE}${digits}"
    fi

    printf '%s' "$final_cid"
}

main() {
    read_config
    agi_read_env

    final_cid="$(normalize_callerid)"

    if [[ -n "$final_cid" ]]; then
        set_agi_variable "CALLERID(num)" "$final_cid"
    fi

    exit 0
}

main "$@"
