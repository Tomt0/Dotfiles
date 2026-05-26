#!/usr/bin/env bash
image="$1"
[[ -z "$image" ]] && exit 1

theme_dir="/usr/share/sddm/themes/sddm-astronaut-theme"
config_rel=$(grep "^ConfigFile=" "$theme_dir/metadata.desktop" | cut -d= -f2)
config_file="$theme_dir/$config_rel"

filename=$(basename "$image")
dest_rel="Backgrounds/$filename"
dest="$theme_dir/$dest_rel"

pkexec sh -c "cp '$image' '$dest' && sed -i 's|^Background=.*|Background=$dest_rel|' '$config_file'"

[[ $? -eq 0 ]] && notify-send "SDDM" "Login screen wallpaper set to $filename" \
    -i preferences-desktop-wallpaper 2>/dev/null
