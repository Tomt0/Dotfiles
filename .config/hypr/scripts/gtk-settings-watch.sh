#!/bin/bash
SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
ENV_CONF="$HOME/.config/hypr/conf/environment.conf"

apply_cursor() {
    local theme size
    theme=$(grep -oP '(?<=gtk-cursor-theme-name=)\S+' "$SETTINGS")
    size=$(grep -oP '(?<=gtk-cursor-theme-size=)\S+' "$SETTINGS")

    [ -z "$theme" ] && return

    sed -i "s/^env = XCURSOR_THEME,.*/env = XCURSOR_THEME,$theme/" "$ENV_CONF"
    sed -i "s/^env = HYPRCURSOR_THEME,.*/env = HYPRCURSOR_THEME,$theme/" "$ENV_CONF"
    [ -n "$size" ] && sed -i "s/^env = XCURSOR_SIZE,.*/env = XCURSOR_SIZE,$size/" "$ENV_CONF"
    [ -n "$size" ] && sed -i "s/^env = HYPRCURSOR_SIZE,.*/env = HYPRCURSOR_SIZE,$size/" "$ENV_CONF"

    hyprctl keyword env "XCURSOR_THEME,$theme" 2>/dev/null
    hyprctl keyword env "HYPRCURSOR_THEME,$theme" 2>/dev/null
    [ -n "$size" ] && hyprctl keyword env "XCURSOR_SIZE,$size" 2>/dev/null
    hyprctl setcursor "$theme" "${size:-24}" 2>/dev/null
    hyprctl reload 2>/dev/null
}

restart_polkit() {
    pkill -x polkit-gnome-au 2>/dev/null
    sleep 0.3
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
}

_prev_gtk_theme=""

inotifywait -m -e close_write "$SETTINGS" 2>/dev/null | while read -r; do
    apply_cursor

    _cur_gtk_theme=$(grep -oP '(?<=gtk-theme-name=)\S+' "$SETTINGS")
    if [ -n "$_cur_gtk_theme" ] && [ "$_cur_gtk_theme" != "$_prev_gtk_theme" ]; then
        _prev_gtk_theme="$_cur_gtk_theme"
        restart_polkit
    fi
done
