#!/usr/bin/env bash

# Arch Linux Desktop Install Script
# Hyprland · Catppuccin Mocha · Waybar · Walker
#
# Based on the original work by ViegPhunt
# https://github.com/ViegPhunt/Arch-Hyprland
#
# Detects whether Hyprland is already installed and acts accordingly:
#   Fresh install  — full setup from scratch, clones dotfiles from GitHub
#   Existing setup — resolves tool conflicts, backs up configs, applies dotfiles

set -uo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
die()     { echo -e "${RED}[error]${RESET} $*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

# ─── Guards ───────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "Run as your regular user, not root. The script calls sudo where needed."
command -v pacman &>/dev/null || die "This script requires Arch Linux."

# ─── Mode detection ───────────────────────────────────────────────────────────
if command -v hyprctl &>/dev/null; then
    MODE="apply"
    command -v yay &>/dev/null || die "yay is required for existing installs. Install it first: https://github.com/Jguer/yay"
else
    MODE="fresh"
fi

# ─── Conflict map (apply mode only) ──────────────────────────────────────────
declare -A CONFLICTS=(
    ["walker"]="rofi rofi-wayland rofi-emoji wofi bemenu fuzzel tofi"
    ["awww"]="swww swaybg hyprpaper feh nitrogen mpvpaper"
    ["swaync"]="mako dunst"
    ["hyprlock"]="swaylock swaylock-effects waylock gtklock"
    ["waybar"]="eww yambar"
    ["sddm"]="ly lightdm lxdm greetd"
)

# ─── Package lists ────────────────────────────────────────────────────────────
AUR_PACKAGES=(
    # Hyprland extras
    wlogout awww uwsm

    # App launcher + backend
    walker elephant-bin elephant-desktopapplications-bin elephant-menus-bin

    # Browsers
    brave-bin

    # Editors & IDEs
    sublime-text-4

    # Theming
    sddm-astronaut-theme
    catppuccin-gtk-theme-mocha catppuccin-qt5ct-git kvantum-theme-catppuccin-git
    ttf-segoe-ui-variable whitesur-icon-theme moga-neon-cursor-theme apple_cursor tint

    # Shell prompt
    oh-my-posh

    # Wallpaper
    waypaper

    # Communication
    spotify

    # Gaming
    xpadneo-dkms balatro-mod-manager-bin

    # Fun CLI
    pokemon-colorscripts-git pipes.sh cbonsai cmatrix

    # Misc
    localsend ani-cli ascii neocities
)

# ─── Intro ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ╔════════════════════════════════════════════╗"
echo "  ║     Tomt0's Desktop Install — Arch Linux  ║"
echo "  ║   Hyprland · Catppuccin Mocha · Waybar    ║"
echo "  ╚════════════════════════════════════════════╝"
echo -e "${RESET}"

if [[ "$MODE" == "fresh" ]]; then
    echo -e "${CYAN}  Detected: fresh install${RESET}"
    echo ""
    echo -e "${YELLOW}  This script will:${RESET}"
    echo "    • Install 90+ packages from pacman and the AUR"
    echo "    • Back up then overwrite your ~/.config/ and ~/.zshrc"
    echo "    • Change your default shell to zsh"
    echo "    • Hyprland will be available at your login screen after reboot"
    echo ""
    echo -e "${YELLOW}  Expect 30–60 minutes depending on your internet speed.${RESET}"
else
    echo -e "${CYAN}  Detected: existing Hyprland install${RESET}"
    echo ""
    echo -e "${YELLOW}  This script will:${RESET}"
    echo "    • Remove tools that conflict with these dotfiles (see below)"
    echo "    • Install any missing packages (skips already-installed ones)"
    echo "    • Back up your existing ~/.config entries to ~/.config-backup-<timestamp>"
    echo "    • Replace configs — your monitors.conf will NOT be touched"
    echo "    • Enable services, set up zsh, zram, gaming opts, SDDM"
    echo ""

    # Scan and show conflicts before the prompt
    _found=0
    for _rep in "${!CONFLICTS[@]}"; do
        for _pkg in ${CONFLICTS[$_rep]}; do
            if pacman -Qi "$_pkg" &>/dev/null; then
                warn "Conflict: $_pkg will be removed → replaced by $_rep"
                _found=1
            fi
        done
    done
    [[ $_found -eq 1 ]] && echo ""
fi

read -rp "  Continue? [y/N] " _confirm
[[ "$_confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
echo ""

# ─── 0. Multilib ──────────────────────────────────────────────────────────────
enable_multilib() {
    section "Multilib repo"
    if grep -q '^\[multilib\]' /etc/pacman.conf; then
        ok "multilib already enabled"
    else
        sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
        sudo sed -i '/^\[multilib\]/{n;s/^#Include/Include/}' /etc/pacman.conf
        ok "multilib enabled"
    fi
    sudo pacman -Syu --noconfirm
    ok "Package databases refreshed and system upgraded"
}

# ─── 0b. Portal conflict check ────────────────────────────────────────────────
check_portal_conflicts() {
    section "Portal conflict check"
    SKIP_WLR_PORTAL=0
    if pacman -Qi xdg-desktop-portal-kde &>/dev/null; then
        warn "xdg-desktop-portal-kde detected — skipping xdg-desktop-portal-wlr"
        SKIP_WLR_PORTAL=1
    fi
    if pacman -Qi xdg-desktop-portal-gnome &>/dev/null; then
        warn "xdg-desktop-portal-gnome detected — skipping xdg-desktop-portal-wlr"
        warn "If screen sharing breaks later, run: sudo pacman -R xdg-desktop-portal-gnome"
        SKIP_WLR_PORTAL=1
    fi
    ok "Portal check done"
}

# ─── 1a. yay (fresh only) ─────────────────────────────────────────────────────
install_yay() {
    section "AUR helper (yay)"
    if command -v yay &>/dev/null; then
        ok "yay already installed"
        return
    fi
    info "Building yay from AUR..."
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp; tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    ok "yay installed"
}

# ─── 1b. Resolve tool conflicts (apply only) ──────────────────────────────────
resolve_conflicts() {
    section "Resolving conflicts"
    local to_remove=()
    for replacement in "${!CONFLICTS[@]}"; do
        for pkg in ${CONFLICTS[$replacement]}; do
            pacman -Qi "$pkg" &>/dev/null && to_remove+=("$pkg")
        done
    done
    if [[ ${#to_remove[@]} -eq 0 ]]; then
        ok "No conflicts found"
        return
    fi
    info "Removing: ${to_remove[*]}"
    sudo pacman -Rns --noconfirm "${to_remove[@]}" 2>&1 && ok "Conflicts removed" \
        || warn "Some packages could not be removed — continuing"
}

# ─── 2. Packages ──────────────────────────────────────────────────────────────
install_packages() {
    local failed=()

    pacman_group() {
        local label="$1"; shift
        info "[$label]"
        if ! sudo pacman -S --needed --noconfirm "$@" 2>&1; then
            warn "One or more packages in '$label' failed — continuing"
            failed+=("pacman:$label")
        fi
    }

    section "Pacman packages"

    pacman_group "Hyprland core" \
        hyprland hypridle hyprlock hyprshot \
        waybar swaync grim slurp kanshi swaybg \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils xdg-user-dirs

    pacman_group "Qt theming" qt5ct qt6ct qt5-wayland qt6-wayland kvantum kvantum-qt5

    pacman_group "Terminal & shell" ghostty zsh zsh-completions tmux

    pacman_group "Fonts" ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk

    pacman_group "Theming" nwg-look papirus-icon-theme gtk-engine-murrine

    pacman_group "Polkit" polkit-gnome

    pacman_group "File manager" nemo gvfs gvfs-afc gvfs-mtp gvfs-smb ark \
        loupe celluloid evince gnome-disk-utility gnome-text-editor gnome-characters

    pacman_group "Networking" networkmanager network-manager-applet wpa_supplicant firewalld

    pacman_group "Bluetooth" bluez bluez-utils blueman

    pacman_group "Audio" pipewire-audio pipewire-pulse wireplumber pavucontrol alsa-firmware sof-firmware

    pacman_group "Clipboard" cliphist wl-clipboard

    pacman_group "Input method" fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-bamboo

    pacman_group "Brightness" brightnessctl

    pacman_group "Wallpaper" libvips

    pacman_group "Dev tools" \
        neovim vim nano git wget rsync stow \
        base-devel cmake ccache gperf patchelf \
        npm python-pip python-pipx rustup github-cli

    pacman_group "CLI tools" bat eza fd fzf zoxide lazygit lazydocker \
        fastfetch htop btop inotify-tools smartmontools

    pacman_group "Media" obs-studio ffmpeg cava playerctl

    pacman_group "Gaming" gamemode

    pacman_group "Security tools" strace ltrace binwalk checksec upx

    pacman_group "Printing" cups cups-pk-helper system-config-printer

    pacman_group "Firewall" firewall-config

    pacman_group "Misc" flatpak fuse2 dpkg zram-generator yad man-db unzip zip keepass

    pacman_group "Display manager" sddm

    if [[ "${SKIP_WLR_PORTAL:-0}" -eq 0 ]]; then
        pacman_group "WLR portal" xdg-desktop-portal-wlr
    fi

    section "AUR packages"
    if ! yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" 2>&1; then
        warn "One or more AUR packages failed — continuing"
        failed+=("aur:bulk")
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo ""
        warn "The following groups had failures:"
        for f in "${failed[@]}"; do echo "    - $f"; done
        warn "Re-run just those groups or install manually with pacman/yay."
    else
        ok "All packages installed"
    fi
}

# ─── 3. Services ──────────────────────────────────────────────────────────────
enable_services() {
    section "System services"
    if systemctl is-active --quiet NetworkManager; then
        ok "NetworkManager already running"
    elif systemctl is-active --quiet iwd || systemctl is-active --quiet dhcpcd \
      || systemctl is-active --quiet systemd-networkd; then
        warn "Another network manager is active — not touching networking"
        sudo systemctl enable NetworkManager
    else
        sudo systemctl enable --now NetworkManager
    fi
    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now firewalld
    sudo systemctl enable --now cups
    systemctl --user enable --now gamemode 2>/dev/null || true
    elephant service enable 2>/dev/null || true
    systemctl --user start elephant 2>/dev/null || true
    ok "Services enabled"
}

# ─── 4. Gaming optimizations ──────────────────────────────────────────────────
setup_gaming() {
    section "Gaming optimizations"
    sudo tee /etc/sysctl.d/99-gaming.conf > /dev/null << 'EOF'
vm.nr_hugepages=128
EOF
    sudo tee /etc/security/limits.d/99-gaming.conf > /dev/null << 'EOF'
@users - rtprio 95
@users - memlock unlimited
EOF
    sudo sysctl --system
    ok "hugepages + realtime audio priority configured"
}

# ─── 5. zram ──────────────────────────────────────────────────────────────────
setup_zram() {
    section "zram swap"
    if [[ -f /etc/systemd/zram-generator.conf ]]; then
        ok "zram already configured"
        return
    fi
    sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    ok "zram configured (ram/2, zstd)"
}

# ─── 6. Scripts ───────────────────────────────────────────────────────────────
setup_scripts() {
    section "viegphunt scripts"

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

    cat > "$dir/wallpaper_select.sh" << 'EOF'
#!/usr/bin/env bash
waypaper
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

    cat > "$dir/walker_start.sh" << 'EOF'
#!/usr/bin/env bash
for i in $(seq 1 30); do
    elephant query "menus:categories;;1" 2>/dev/null | grep -q 'text:' && break
    sleep 1
done
exec walker --gapplication-service
EOF

    chmod +x "$dir"/*.sh
    mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
    ok "Scripts written to $dir"

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
    chmod +x "$hypr_scripts/gtk-settings-watch.sh"
    ok "gtk-settings-watch.sh written"
}

# ─── 7. Display manager ───────────────────────────────────────────────────────
setup_display_manager() {
    section "Display manager"

    sudo systemctl enable sddm
    ok "sddm enabled"

    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << 'EOF'
[Theme]
Current=sddm-astronaut-theme
EOF
    ok "SDDM theme set to sddm-astronaut-theme"

    local session_file="/usr/share/wayland-sessions/hyprland-uwsm.desktop"
    if [[ ! -f "$session_file" ]]; then
        sudo mkdir -p /usr/share/wayland-sessions
        sudo tee "$session_file" > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland (UWSM)
Comment=An intelligent dynamic tiling Wayland compositor
Exec=uwsm start -- hyprland
DesktopNames=Hyprland
Type=Application
EOF
        ok "Wayland session entry written"
    else
        ok "Session entry already exists"
    fi
}

# ─── 8. Shell ─────────────────────────────────────────────────────────────────
setup_shell() {
    section "Default shell"
    if [[ "$SHELL" == */zsh ]]; then
        ok "zsh is already the default shell"
        return
    fi
    local zsh_path; zsh_path=$(command -v zsh)
    info "Changing default shell to zsh — you may be prompted for your password"
    chsh -s "$zsh_path"
    ok "Default shell set to zsh (takes effect on next login)"
}

# ─── 9a. Dotfiles — fresh install ─────────────────────────────────────────────
setup_dotfiles_fresh() {
    section "Dotfiles"

    local repo="https://github.com/Tomt0/Dotfiles.git"
    local dotfiles="$HOME/dotfiles"

    if [[ -d "$dotfiles/.git" ]]; then
        info "Dotfiles repo already present — pulling latest..."
        git -C "$dotfiles" pull --ff-only
    else
        info "Cloning dotfiles..."
        git clone "$repo" "$dotfiles"
    fi

    info "Backing up existing configs..."
    local backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup"
    while IFS= read -r -d '' src_dir; do
        local name; name=$(basename "$src_dir")
        [[ -d "$HOME/.config/$name" ]] && cp -r "$HOME/.config/$name" "$backup/$name"
    done < <(find "$dotfiles/.config" -mindepth 1 -maxdepth 1 -type d -print0)
    for f in .zshrc .tmux.conf; do
        [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$backup/$f"
    done
    ok "Backup saved to $backup"

    info "Applying configs..."
    rsync -a --exclude='*.swp' "$dotfiles/.config/" "$HOME/.config/"
    ok ".config applied"

    for f in .zshrc .tmux.conf; do
        [[ -f "$dotfiles/$f" ]] && cp "$dotfiles/$f" "$HOME/$f" && ok "$f applied"
    done

    info "Copying wallpapers..."
    rsync -a "$dotfiles/wallpapers/" "$HOME/Pictures/Wallpapers/"
    ok "Wallpapers applied"
}

# ─── 9b. Dotfiles — existing install ──────────────────────────────────────────
setup_dotfiles_apply() {
    section "Dotfiles"

    # When run via curl (bash <(curl ...)) BASH_SOURCE[0] is a file descriptor,
    # not a directory. Fall back to cloning/pulling the repo in that case.
    local dotfiles
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
    if [[ -d "$script_dir/.config/hypr" ]]; then
        dotfiles="$script_dir"
    else
        local repo="https://github.com/Tomt0/Dotfiles.git"
        dotfiles="$HOME/dotfiles"
        if [[ -d "$dotfiles/.git" ]]; then
            info "Pulling latest dotfiles..."
            git -C "$dotfiles" pull --ff-only
        else
            info "Cloning dotfiles..."
            git clone "$repo" "$dotfiles"
        fi
    fi

    info "Backing up existing configs..."
    local backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup"
    local dirs=(
        hypr waybar swaync walker ghostty nvim ohmyposh
        qt5ct qt6ct Kvantum gtk-3.0 gtk-4.0 wlogout
        cava mpv nwg-look waypaper viegphunt elephant
    )
    for d in "${dirs[@]}"; do
        [[ -d "$HOME/.config/$d" ]] && cp -r "$HOME/.config/$d" "$backup/$d" \
            && info "Backed up: ~/.config/$d"
    done
    for f in .zshrc .tmux.conf; do
        [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$backup/$f" && info "Backed up: ~/$f"
    done
    ok "Backup saved to $backup"

    info "Applying configs..."
    local copy_dirs=(
        waybar swaync walker ghostty nvim ohmyposh
        qt5ct qt6ct Kvantum gtk-3.0 gtk-4.0 wlogout
        cava mpv nwg-look waypaper elephant
    )
    for d in "${copy_dirs[@]}"; do
        if [[ -d "$dotfiles/.config/$d" ]]; then
            rm -rf "$HOME/.config/$d"
            cp -r "$dotfiles/.config/$d" "$HOME/.config/$d"
            ok "$d"
        fi
    done

    # Hypr: copy everything except monitors.conf
    mkdir -p "$HOME/.config/hypr"
    local hypr_src="$dotfiles/.config/hypr"
    find "$hypr_src" -mindepth 1 | while IFS= read -r src; do
        local rel="${src#$hypr_src/}"
        local dst="$HOME/.config/hypr/$rel"
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

    info "Copying wallpapers..."
    rsync -a "$dotfiles/wallpapers/" "$HOME/Pictures/Wallpapers/"
    ok "Wallpapers applied"

    if pgrep -x walker &>/dev/null; then
        pkill -x walker
        sleep 0.5
        walker --gapplication-service &
        ok "Walker restarted"
    fi
}

# ─── 10. Apply themes ─────────────────────────────────────────────────────────
apply_themes() {
    section "Applying themes"
    bash "$HOME/.config/viegphunt/gtkthemes.sh" && ok "GTK theme applied"
    bash "$HOME/.config/viegphunt/setcursor.sh" && ok "Cursor theme applied"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    enable_multilib
    check_portal_conflicts

    if [[ "$MODE" == "fresh" ]]; then
        install_yay
    fi
    resolve_conflicts

    install_packages
    enable_services
    setup_gaming
    setup_zram
    setup_scripts
    setup_display_manager
    setup_shell

    if [[ "$MODE" == "fresh" ]]; then
        setup_dotfiles_fresh
    else
        setup_dotfiles_apply
        apply_themes
    fi

    echo ""
    echo -e "${BOLD}${GREEN}  ✓ Done!${RESET}"
    echo ""
    if [[ "$MODE" == "fresh" ]]; then
        echo "  Reboot and log into Hyprland."
    else
        echo "  Log out and back in (or reboot) to see all changes."
        echo "  Wallpapers go in ~/Pictures/Wallpapers/"
    fi
    echo ""
}

main "$@"
