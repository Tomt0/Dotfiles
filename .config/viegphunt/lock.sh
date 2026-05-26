#!/usr/bin/env bash
current_wallpaper=$(/usr/bin/awww query | grep -oP "(?<=image: ).*" | head -1)
if [[ -z "$current_wallpaper" ]]; then
    current_wallpaper=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | shuf -n1)
fi
[[ -n "$current_wallpaper" ]] && ln -sf "$current_wallpaper" "$HOME/.cache/hyprlock_wallpaper"
pidof hyprlock || hyprlock --grace 0
