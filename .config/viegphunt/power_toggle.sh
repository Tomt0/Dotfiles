#!/usr/bin/env bash
current=$(powerprofilesctl get 2>/dev/null) || exit 0

if [[ "$1" == "--status" ]]; then
    case "$current" in
        performance) echo '{"text":"󰾅","tooltip":"Performance","class":"performance"}';;
        power-saver)  echo '{"text":"󰾁","tooltip":"Power Saver","class":"power-saver"}';;
        *)            echo '{"text":"󰾆","tooltip":"Balanced","class":"balanced"}';;
    esac
    exit 0
fi

if [[ "$current" == "performance" ]]; then
    powerprofilesctl set power-saver
else
    powerprofilesctl set performance
fi
