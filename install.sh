#!/usr/bin/env bash

# ViegPhunt — Arch Linux Desktop Install Script
# Hyprland · Catppuccin Mocha · Waybar · Walker

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

# ─── Package lists ────────────────────────────────────────────────────────────

PACMAN_PACKAGES=(
    # Hyprland & Wayland core
    hyprland hypridle hyprlock hyprpaper hyprpolkitagent hyprshot
    waybar swaync grim slurp kanshi swaybg
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xdg-utils xdg-user-dirs
    # Note: xdg-desktop-portal-wlr conflicts with xdg-desktop-portal-kde.
    # It is installed below only if kde portal is not already present.

    # Qt theming (qt5ct/qt6ct + kvantum style engine)
    qt5ct qt6ct qt5-wayland qt6-wayland
    kvantum kvantum-qt5


    # Terminal & shell
    ghostty zsh zsh-completions tmux

    # Fonts
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk

    # Theming
    nwg-look papirus-icon-theme gtk-engine-murrine

    # Audio
    wireplumber

    # Polkit
    polkit-gnome

    # File manager & desktop utils
    nemo gvfs gvfs-afc gvfs-mtp gvfs-smb ark
    loupe celluloid evince gnome-disk-utility gnome-text-editor gnome-characters

    # Networking
    networkmanager network-manager-applet wpa_supplicant firewalld

    # Bluetooth
    bluez bluez-utils blueman

    # Audio
    pipewire-audio pipewire-pulse pavucontrol alsa-firmware sof-firmware

    # Clipboard
    cliphist wl-clipboard

    # Input method
    fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-bamboo

    # Rofi (used for app launcher, emoji, clipboard popups)
    rofi-wayland
    rofi-emoji

    # Brightness (media keys — also useful for monitors with DDC/CI)
    brightnessctl

    # Wallpaper effects dependency
    libvips

    # Developer tools
    neovim vim nano
    git wget rsync stow
    base-devel cmake ccache gperf patchelf
    npm python-pip python-pipx rustup
    github-cli

    # CLI tools
    bat eza fd fzf zoxide
    lazygit lazydocker
    fastfetch htop btop inotify-tools smartmontools

    # Media
    obs-studio ffmpeg cava playerctl

    # Gaming / performance
    gamemode steam
    retroarch retroarch-assets-ozone retroarch-assets-xmb

    # Security / CTF tools
    strace ltrace binwalk checksec upx

    # Printing
    cups cups-pk-helper system-config-printer

    # Firewall GUI
    firewall-config

    # Misc
    flatpak fuse2 dpkg
    zram-generator yad
    man-db unzip zip
    keepass
)

AUR_PACKAGES=(
    # Hyprland extras
    wlogout
    awww

    # App launcher
    walker
    elephant-bin
    elephant-desktopapplications-bin
    elephant-menus-bin

    # Browsers
    brave-bin
    zen-browser-bin

    # Editors & IDEs
    visual-studio-code-bin
    sublime-text-4

    # Theming
    catppuccin-gtk-theme-mocha
    catppuccin-qt5ct-git
    kvantum-theme-catppuccin-git
    ttf-segoe-ui-variable
    whitesur-icon-theme
    moga-neon-cursor-theme
    apple_cursor
    tint

    # Shell prompt
    oh-my-posh

    # Wallpaper
    waypaper

    # Communication
    spotify
    legcord
    arrpc

    # Gaming
    xpadneo-dkms
    balatro-mod-manager-bin
    dolphin-emu

    # Fun CLI
    pokemon-colorscripts-git
    pipes.sh
    cbonsai
    cmatrix

    # Misc
    localsend
    ani-cli
    crunchyroll
    ascii
    neocities

)
# yay is intentionally omitted here — install_yay() handles it before this list runs.

# ─── 0. Multilib ──────────────────────────────────────────────────────────────
enable_multilib() {
    section "Enabling multilib repo"

    if grep -q '^\[multilib\]' /etc/pacman.conf; then
        ok "multilib already enabled"
    else
        sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
        sudo sed -i '/^\[multilib\]/{n;s/^#Include/Include/}' /etc/pacman.conf
        ok "multilib enabled"
    fi

    sudo pacman -Sy --noconfirm
    ok "Package databases refreshed"
}

# ─── 0b. Conflict check ───────────────────────────────────────────────────────
check_conflicts() {
    section "Conflict check"

    # xdg-desktop-portal-wlr conflicts with xdg-desktop-portal-kde
    if pacman -Qi xdg-desktop-portal-kde &>/dev/null; then
        warn "xdg-desktop-portal-kde is installed — skipping xdg-desktop-portal-wlr to avoid conflict."
        warn "Hyprland will use xdg-desktop-portal-hyprland instead (this is fine)."
        SKIP_WLR_PORTAL=1
    else
        SKIP_WLR_PORTAL=0
    fi

    ok "Conflict check done"
}

# ─── 1. yay ───────────────────────────────────────────────────────────────────
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

# ─── 3. Packages ──────────────────────────────────────────────────────────────
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
        hyprland hypridle hyprlock hyprpaper hyprpolkitagent hyprshot \
        waybar swaync grim slurp kanshi swaybg \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils \
        xdg-user-dirs

    pacman_group "Qt theming" \
        qt5ct qt6ct qt5-wayland qt6-wayland \
        kvantum kvantum-qt5

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

    pacman_group "Rofi" rofi-wayland rofi-emoji

    pacman_group "Brightness" brightnessctl

    pacman_group "Wallpaper" libvips

    pacman_group "Dev tools" \
        neovim vim nano git wget rsync stow \
        base-devel cmake ccache gperf patchelf \
        npm python-pip python-pipx rustup github-cli

    pacman_group "CLI tools" bat eza fd fzf zoxide lazygit lazydocker \
        fastfetch htop btop inotify-tools smartmontools

    pacman_group "Media" obs-studio ffmpeg cava playerctl

    pacman_group "Gaming" gamemode steam retroarch retroarch-assets-ozone retroarch-assets-xmb

    pacman_group "Security tools" strace ltrace binwalk checksec upx

    pacman_group "Printing" cups cups-pk-helper system-config-printer

    pacman_group "Firewall" firewall-config

    pacman_group "Misc" flatpak fuse2 dpkg zram-generator yad man-db unzip zip keepass

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

# ─── 4. Services ──────────────────────────────────────────────────────────────
enable_services() {
    section "System services"
    sudo systemctl enable --now NetworkManager
    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now firewalld
    sudo systemctl enable --now cups
    systemctl --user enable --now gamemode 2>/dev/null || true
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

# ─── 7. Scripts ───────────────────────────────────────────────────────────────
setup_scripts() {
    section "viegphunt scripts"

    local dir="$HOME/.config/viegphunt"
    mkdir -p "$dir"

    # ── App launcher (Super+A) ────────────────────────────────────────────────
    cat > "$dir/app_launcher.sh" << 'EOF'
#!/usr/bin/env bash
if pidof rofi > /dev/null; then pkill rofi; fi
rofi -show drun
EOF

    # ── Clipboard picker (Super+V) ────────────────────────────────────────────
    cat > "$dir/clipboard_launcher.sh" << 'EOF'
#!/usr/bin/env bash
if pidof rofi > /dev/null; then pkill rofi; fi
cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy
EOF

    # ── Emoji picker (Super+.) ────────────────────────────────────────────────
    cat > "$dir/emoji_launcher.sh" << 'EOF'
#!/usr/bin/env bash
if pidof rofi > /dev/null; then pkill rofi; fi
rofi -show emoji
EOF

    # ── Lock screen (Super+L) ─────────────────────────────────────────────────
    cat > "$dir/lock.sh" << 'EOF'
#!/usr/bin/env bash
current_wallpaper=$(/usr/bin/awww query | grep -oP "(?<=image: ).*" | head -1)
ln -sf "$current_wallpaper" "$HOME/.cache/hyprlock_wallpaper"
pidof hyprlock || hyprlock --grace 0
EOF

    # ── GTK theme apply ───────────────────────────────────────────────────────
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

    # ── Cursor theme setup ────────────────────────────────────────────────────
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

    # ── Keybinding hint overlay (Super+H) ─────────────────────────────────────
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

    # ── Backup dotfiles before stow ───────────────────────────────────────────
    cat > "$dir/backup_config.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
timestamp=$(date +"%Y%m%d-%H%M%S")
backup_dir="$HOME/.backup-$timestamp"
dotfiles_root="$(pwd)"
echo "==> Backing up existing config files before stowing"
echo "==> Backup will be saved to: $backup_dir"
mkdir -p "$backup_dir"
targets=(".zshrc" ".tmux.conf")
while IFS= read -r -d '' dir; do
    targets+=("${dir#$dotfiles_root/}")
done < <(find "$dotfiles_root/.config" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
for target in "${targets[@]}"; do
    src="$HOME/$target"
    if [[ -e "$src" && ! -L "$src" ]]; then
        dest="$backup_dir/$target"
        mkdir -p "$(dirname "$dest")"
        mv "$src" "$dest"
        echo "-> Backed up: $target"
    fi
done
echo "Backup completed to $backup_dir"
EOF

    # ── Wallpaper selector ────────────────────────────────────────────────────
    cat > "$dir/wallpaper_select.sh" << 'EOF'
#!/usr/bin/env bash
if pidof rofi > /dev/null; then pkill rofi; fi
wallpapers_dir="$HOME/Pictures/Wallpapers"
selected_wallpaper=$(for a in "$wallpapers_dir"/*; do
    echo -en "$(basename "${a%.*}")\0icon\x1f$a\n"
done | rofi -dmenu -p " ")
image_fullname_path=$(find "$wallpapers_dir" -type f -name "$selected_wallpaper.*" | head -n 1)
awww img "$image_fullname_path" --transition-type any --transition-duration 2
~/.config/viegphunt/wallpaper_effects.sh
EOF

    # ── Random wallpaper (Super+Shift+W) ──────────────────────────────────────
    cat > "$dir/wallpaper_random.sh" << 'EOF'
#!/usr/bin/env bash
wallpapers_dir="$HOME/Pictures/Wallpapers"
random_wallpaper=$(find "$wallpapers_dir" -maxdepth 1 -type f | shuf -n 1)
awww img "$random_wallpaper" --transition-type any --transition-duration 2
~/.config/viegphunt/wallpaper_effects.sh
EOF

    # ── Wallpaper effects (blur cache for hyprlock) ───────────────────────────
    cat > "$dir/wallpaper_effects.sh" << 'EOF'
#!/usr/bin/env bash
current_wallpaper_path=$(awww query | head -n 1 | awk -F'image: ' '/image:/ {print $2; exit}')
destination_wallpaper_dir="$HOME/.cache/awww"
mkdir -p "$destination_wallpaper_dir"
rm -f "$destination_wallpaper_dir/normal.png"
vipsthumbnail "$current_wallpaper_path" -o "$destination_wallpaper_dir/normal.png"
EOF

    chmod +x "$dir"/*.sh
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/Pictures/Screenshots"
    ok "All viegphunt scripts written to $dir"

    # ── gtk-settings-watch.sh (Hyprland script) ───────────────────────────────
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
    ok "gtk-settings-watch.sh written to $hypr_scripts"
}

# ─── 9. Default shell ─────────────────────────────────────────────────────────
setup_shell() {
    section "Default shell"

    if [[ "$SHELL" == */zsh ]]; then
        ok "zsh is already the default shell"
        return
    fi

    local zsh_path
    zsh_path=$(command -v zsh)
    chsh -s "$zsh_path"
    ok "Default shell set to zsh (takes effect on next login)"
}

# ─── 10. Dotfiles ─────────────────────────────────────────────────────────────
setup_dotfiles() {
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

    info "Applying configs to ~/.config/ ..."
    rsync -a --exclude='*.swp' "$dotfiles/.config/" "$HOME/.config/"
    ok ".config applied"

    for f in .zshrc .tmux.conf; do
        [[ -f "$dotfiles/$f" ]] && cp "$dotfiles/$f" "$HOME/$f" && ok "$f applied"
    done

    info "Copying wallpapers to ~/Pictures/Wallpapers/ ..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    rsync -a "$dotfiles/wallpapers/" "$HOME/Pictures/Wallpapers/"
    ok "Wallpapers applied"

    info "Applying GTK theme..."
    bash "$HOME/.config/viegphunt/gtkthemes.sh" && ok "GTK theme applied"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}${CYAN}"
    echo "  ╔════════════════════════════════════════════╗"
    echo "  ║   ViegPhunt Desktop Install — Arch Linux  ║"
    echo "  ║   Hyprland · Catppuccin Mocha · Waybar    ║"
    echo "  ╚════════════════════════════════════════════╝"
    echo -e "${RESET}"

    enable_multilib
    check_conflicts
    install_yay
    install_packages
    enable_services
    setup_gaming
    setup_zram
    setup_scripts
    setup_shell
    setup_dotfiles

    echo ""
    echo -e "${BOLD}${GREEN}  ✓ Installation complete!${RESET}"
    echo ""
    echo "  Reboot and log into Hyprland."
    echo ""
}

main "$@"
