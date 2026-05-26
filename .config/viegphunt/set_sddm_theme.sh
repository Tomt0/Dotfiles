#!/usr/bin/env bash
theme="$1"
[[ -z "$theme" ]] && exit 1

tmp=$(mktemp /tmp/sddm-theme-XXXXXX.conf)
printf '[Theme]\nCurrent=%s\n' "$theme" > "$tmp"

pkexec sh -c "mkdir -p /etc/sddm.conf.d && cp '$tmp' /etc/sddm.conf.d/theme.conf"
ret=$?
rm -f "$tmp"

if [[ $ret -eq 0 ]]; then
    notify-send "SDDM" "Theme set to $theme" -i preferences-desktop-theme 2>/dev/null
fi
