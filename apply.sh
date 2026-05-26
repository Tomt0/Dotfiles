#!/usr/bin/env bash

# Tomt0 Dotfiles — Apply Script
# For users who already have Hyprland set up.
# Backs up existing configs and replaces them with these dotfiles.

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
die()     { echo -e "${RED}[error]${RESET} $*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

# ─── Guards ───────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "Run as your regular user, not root."
command -v pacman &>/dev/null || die "This script requires Arch Linux."
command -v hyprctl &>/dev/null || die "Hyprland doesn't appear to be installed."
command -v yay &>/dev/null    || die "yay is required. Install it first: https://github.com/Jguer/yay"

# ─── Packages needed for these dotfiles ───────────────────────────────────────
PACMAN_DEPS=(
    # Hyprland extras
    hypridle hyprlock hyprshot
    waybar swaync kanshi
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

    # Qt theming
    qt5ct qt6ct qt5-wayland qt6-wayland
    kvantum kvantum-qt5

    # Theming
    nwg-look papirus-icon-theme gtk-engine-murrine

    # Fonts
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk

    # Terminal & shell
    ghostty zsh zsh-completions tmux

    # Tools referenced in configs/scripts
    wl-clipboard cliphist
    brightnessctl playerctl
    grim slurp
    rofi-wayland
    yad
    inotify-tools
    libvips
    wlogout
)

AUR_DEPS=(
    # Wallpaper daemon (used by lock screen and scripts)
    awww

    # App launcher + backend
    walker
    elephant-bin
    elephant-desktopapplications-bin
    elephant-menus-bin

    # Wayland session manager
    uwsm

    # Theming
    catppuccin-gtk-theme-mocha
    catppuccin-qt5ct-git
    kvantum-theme-catppuccin-git
    ttf-segoe-ui-variable
    whitesur-icon-theme
    moga-neon-cursor-theme
    apple_cursor

    # Shell prompt
    oh-my-posh

    # Wallpaper picker
    waypaper
)

# ─── Intro ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ╔════════════════════════════════════════════╗"
echo "  ║     Tomt0's Dotfiles — Apply Script       ║"
echo "  ║   Hyprland · Catppuccin Mocha · Waybar    ║"
echo "  ╚════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${YELLOW}  This script will:${RESET}"
echo "    • Install packages required by these dotfiles"
echo "    • Back up your existing ~/.config entries to ~/.config-backup-<timestamp>"
echo "    • Replace configs for: hypr, waybar, swaync, walker, ghostty,"
echo "      nvim, ohmyposh, qt5ct, qt6ct, Kvantum, gtk-3.0, gtk-4.0,"
echo "      wlogout, cava, mpv, nwg-look, waypaper, viegphunt scripts"
echo ""
echo -e "${YELLOW}  Your monitors.conf will NOT be touched.${RESET}"
echo ""
read -rp "  Continue? [y/N] " _confirm
[[ "$_confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
echo ""

# ─── 1. Install dependencies ──────────────────────────────────────────────────
install_deps() {
    section "Installing dependencies"

    info "pacman packages..."
    if ! sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}" 2>&1; then
        warn "One or more pacman packages failed — continuing"
    fi

    info "AUR packages..."
    if ! yay -S --needed --noconfirm "${AUR_DEPS[@]}" 2>&1; then
        warn "One or more AUR packages failed — continuing"
    fi

    ok "Dependencies done"
}

# ─── 2. Backup ────────────────────────────────────────────────────────────────
backup_configs() {
    section "Backing up existing configs"

    local backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup"

    local dirs=(
        hypr waybar swaync walker ghostty nvim ohmyposh
        qt5ct qt6ct Kvantum gtk-3.0 gtk-4.0 wlogout
        cava mpv nwg-look waypaper viegphunt
    )

    for d in "${dirs[@]}"; do
        if [[ -d "$HOME/.config/$d" ]]; then
            cp -r "$HOME/.config/$d" "$backup/$d"
            info "Backed up: ~/.config/$d"
        fi
    done

    for f in .zshrc .tmux.conf; do
        [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$backup/$f" && info "Backed up: ~/$f"
    done

    ok "Backup saved to $backup"
}

# ─── 3. Apply configs ─────────────────────────────────────────────────────────
apply_configs() {
    section "Applying configs"

    local dotfiles
    dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local dirs=(
        waybar swaync walker ghostty nvim ohmyposh
        qt5ct qt6ct Kvantum gtk-3.0 gtk-4.0 wlogout
        cava mpv nwg-look waypaper
    )

    for d in "${dirs[@]}"; do
        if [[ -d "$dotfiles/.config/$d" ]]; then
            rm -rf "$HOME/.config/$d"
            cp -r "$dotfiles/.config/$d" "$HOME/.config/$d"
            ok "$d"
        fi
    done

    # Hypr: replace everything except monitors.conf
    mkdir -p "$HOME/.config/hypr"
    local hypr_src="$dotfiles/.config/hypr"
    find "$hypr_src" -mindepth 1 | while IFS= read -r src; do
        rel="${src#$hypr_src/}"
        dst="$HOME/.config/hypr/$rel"
        if [[ -d "$src" ]]; then
            mkdir -p "$dst"
        elif [[ "$rel" == "conf/monitors.conf" ]]; then
            info "Skipping monitors.conf — keeping yours"
        else
            cp "$src" "$dst"
            ok "hypr/$rel"
        fi
    done

    for f in .zshrc .tmux.conf; do
        [[ -f "$dotfiles/$f" ]] && cp "$dotfiles/$f" "$HOME/$f" && ok "$f"
    done

    mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
    ok "Wallpaper and screenshot directories created"
}

# ─── 4. Viegphunt scripts ─────────────────────────────────────────────────────
setup_scripts() {
    section "Viegphunt scripts"

    local dir="$HOME/.config/viegphunt"
    mkdir -p "$dir"

    cat > "$dir/app_launcher.sh" << 'EOF'
#!/usr/bin/env bash
walker
EOF

    cat > "$dir/clipboard_launcher.sh" << 'EOF'
#!/usr/bin/env bash
walker -m clipboard
EOF

    cat > "$dir/emoji_launcher.sh" << 'EOF'
#!/usr/bin/env bash
walker -m emojis
EOF

    cat > "$dir/lock.sh" << 'EOF'
#!/usr/bin/env bash
current_wallpaper=$(/usr/bin/awww query | grep -oP "(?<=image: ).*" | head -1)
ln -sf "$current_wallpaper" "$HOME/.cache/hyprlock_wallpaper"
pidof hyprlock || hyprlock --grace 0
EOF

    cat > "$dir/gtkthemes.sh" << 'EOF'
#!/usr/bin/env bash
SCHEME="prefer-dark"
THEME="catppuccin-mocha-sapphire-standard+default"
ICONS="WhiteSur-dark"
UI_FONT="Segoe UI Variable Static Text 12"
MONO_FONT="JetBrainsMono Nerd Font 12"
SCHEMA="gsettings set org.gnome.desktop.interface"
${SCHEMA} color-scheme "$SCHEME"
${SCHEMA} gtk-theme "$THEME"
${SCHEMA} icon-theme "$ICONS"
${SCHEMA} font-name "$UI_FONT"
${SCHEMA} monospace-font-name "$MONO_FONT"
EOF

    cat > "$dir/setcursor.sh" << 'EOF'
#!/usr/bin/env bash
mkdir -p ~/.icons/default/
cat > ~/.icons/default/index.theme << 'THEME'
[icon theme]
Inherits=Moga-Neon-Cyan
THEME
sudo mkdir -p /usr/share/icons/default
sudo cp ~/.icons/default/index.theme /usr/share/icons/default/index.theme
EOF

    cat > "$dir/wallpaper_random.sh" << 'EOF'
#!/usr/bin/env bash
wallpapers_dir="$HOME/Pictures/Wallpapers"
random_wallpaper=$(find "$wallpapers_dir" -maxdepth 1 -type f | shuf -n 1)
awww img "$random_wallpaper" --transition-type any --transition-duration 2
~/.config/viegphunt/wallpaper_effects.sh
EOF

    cat > "$dir/wallpaper_effects.sh" << 'EOF'
#!/usr/bin/env bash
current_wallpaper_path=$(awww query | head -n 1 | awk -F'image: ' '/image:/ {print $2; exit}')
destination_wallpaper_dir="$HOME/.cache/awww"
mkdir -p "$destination_wallpaper_dir"
rm -f "$destination_wallpaper_dir/normal.png"
vipsthumbnail "$current_wallpaper_path" -o "$destination_wallpaper_dir/normal.png"
EOF

    cat > "$dir/wallpaper_select.sh" << 'EOF'
#!/usr/bin/env bash
waypaper
EOF

    cat > "$dir/key_hints.sh" << 'EOF'
#!/usr/bin/env bash
if pidof yad > /dev/null; then pkill yad; fi
yad --center --title="Keybinding Hints" --no-buttons --list \
    --column=Key: --column="" --column=Description: \
    --timeout-indicator=bottom \
"  =   "          "  "  "SUPER KEY (Windows Key)" \
"" "" "" \
"  H"              "  "  "Show keybinding hints" \
"  T"              "  "  "Open terminal" \
"  E"              "  "  "Open file manager" \
"  B"              "  "  "Open browser" \
"" "" "" \
"  Shift Ctrl Esc" "  "  "Exit Hyprland" \
"  Q"              "  "  "Close active window" \
"  Shift Q"        "  "  "Kill active window by PID" \
"" "" "" \
"  W"              "  "  "Toggle floating" \
"  Shift P"        "  "  "Pin window (float on all workspaces)" \
"  P"              "  "  "Toggle pseudo (dwindle)" \
"" "" "" \
"  L"              "  "  "Lock screen" \
"  A"              "  "  "App launcher" \
"  ."              "  "  "Emoji selector" \
"  V"              "  "  "Clipboard manager" \
"  Shift W"        "  "  "Random wallpaper" \
"  Shift S"        "  "  "Screenshot (region)" \
"" "" "" \
"  [1-0]"          "  "  "Switch workspace 1-10" \
"  Shift [1-0]"    "  "  "Move window to workspace 1-10"
EOF

    local hypr_scripts="$HOME/.config/hypr/scripts"
    mkdir -p "$hypr_scripts"
    cat > "$hypr_scripts/gtk-settings-watch.sh" << 'EOF'
#!/bin/bash
SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
ENV_CONF="$HOME/.config/hypr/conf/environment.conf"

apply_cursor() {
    local theme size
    theme=$(grep -oP '(?<=gtk-cursor-theme-name=)\S+' "$SETTINGS")
    size=$(grep -oP '(?<=gtk-cursor-theme-size=)\S+' "$SETTINGS")
    [ -z "$theme" ] && return
    sed -i "s/^env = XCURSOR_THEME,.*/env = XCURSOR_THEME,$theme/" "$ENV_CONF"
    [ -n "$size" ] && sed -i "s/^env = XCURSOR_SIZE,.*/env = XCURSOR_SIZE,$size/" "$ENV_CONF"
    [ -n "$size" ] && sed -i "s/^env = HYPRCURSOR_SIZE,.*/env = HYPRCURSOR_SIZE,$size/" "$ENV_CONF"
    hyprctl keyword env "XCURSOR_THEME,$theme" 2>/dev/null
    [ -n "$size" ] && hyprctl keyword env "XCURSOR_SIZE,$size" 2>/dev/null
    hyprctl setcursor "$theme" "${size:-24}" 2>/dev/null
    hyprctl reload 2>/dev/null
}

inotifywait -m -e close_write "$SETTINGS" 2>/dev/null | while read -r; do
    apply_cursor
done
EOF

    chmod +x "$dir"/*.sh "$hypr_scripts"/*.sh
    ok "Scripts written"
}

# ─── 5. Apply themes ──────────────────────────────────────────────────────────
apply_themes() {
    section "Applying themes"

    info "GTK theme..."
    bash "$HOME/.config/viegphunt/gtkthemes.sh" && ok "GTK theme applied"

    info "Cursor theme..."
    bash "$HOME/.config/viegphunt/setcursor.sh" && ok "Cursor theme applied"
}

# ─── 6. Wayland session entry ─────────────────────────────────────────────────
setup_session_entry() {
    section "Wayland session entry"

    local session_file="/usr/share/wayland-sessions/hyprland-uwsm.desktop"
    if [[ -f "$session_file" ]]; then
        ok "Session entry already exists"
        return
    fi

    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee "$session_file" > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland (UWSM)
Comment=An intelligent dynamic tiling Wayland compositor
Exec=uwsm start -- hyprland
DesktopNames=Hyprland
Type=Application
EOF
    ok "Session entry written to $session_file"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    install_deps
    backup_configs
    apply_configs
    setup_scripts
    apply_themes
    setup_session_entry

    echo ""
    echo -e "${BOLD}${GREEN}  ✓ Done!${RESET}"
    echo ""
    echo "  Log out and back in (or reload Hyprland) to see all changes."
    echo "  Wallpapers go in ~/Pictures/Wallpapers/"
    echo ""
}

main "$@"
