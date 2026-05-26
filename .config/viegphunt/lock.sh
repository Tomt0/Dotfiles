#!/usr/bin/env bash
current_wallpaper=$(/usr/bin/awww query | grep -oP "(?<=image: ).*" | head -1)
ln -sf "$current_wallpaper" "$HOME/.cache/hyprlock_wallpaper"
pidof hyprlock || hyprlock --grace 0
