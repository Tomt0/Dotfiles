#!/usr/bin/env bash

count=$(checkupdates 2>/dev/null | wc -l)
if [[ "$count" -gt 0 ]]; then
    echo "{\"text\":\"󰮯 $count\",\"tooltip\":\"$count update(s) available\",\"class\":\"updates\"}"
else
    echo "{\"text\":\"󰮯 0\",\"tooltip\":\"System up to date\",\"class\":\"no-updates\"}"
fi
