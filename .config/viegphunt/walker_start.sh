#!/usr/bin/env bash
for i in $(seq 1 30); do
    elephant query "menus:categories;;1" 2>/dev/null | grep -q 'text:' && break
    sleep 1
done

for provider in games internet media dev system wallpaper; do
    elephant query "menus:${provider};;256" 2>/dev/null &
done
wait

exec walker --gapplication-service
