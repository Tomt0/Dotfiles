# Tomt0's Dotfiles
this whole repo was made by ai fyi, i just made this so i dont need to configue hyprland every time

Arch Linux desktop — Hyprland · Catppuccin Mocha Sapphire · Waybar · Walker

## Install

One script handles both cases — it detects whether Hyprland is already installed and acts accordingly.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Tomt0/Dotfiles/main/install.sh)
```

### Fresh Arch install

- Installs all packages (pacman + AUR via yay, which is also installed automatically)
- Enables services, configures gaming optimisations and zram
- Sets up SDDM with the astronaut theme
- Clones this repo and applies all configs
- Copies wallpapers to `~/Pictures/Wallpapers/`
- Changes default shell to zsh

### Existing Hyprland setup

- Detects and removes conflicting tools before doing anything else:

  | Removed | Replaced by |
  |---------|-------------|
  | rofi, wofi, bemenu, fuzzel, tofi | walker |
  | swww, swaybg, hyprpaper, feh, nitrogen | awww |
  | mako, dunst | swaync |
  | swaylock, waylock, gtklock | hyprlock |
  | eww, yambar | waybar |
  | polkit-kde-agent, hyprpolkitagent, mate-polkit | polkit-gnome |

- Installs any missing packages (skips already-installed ones)
- Backs up your existing `~/.config` entries to `~/.config-backup-<timestamp>`
- Applies all configs — **your `monitors.conf` is not touched**
- Applies GTK and cursor themes immediately

> **Note:** yay must already be installed for the existing-install path.

## Packages

### Pacman

| Category | Packages |
|----------|----------|
| Hyprland core | hyprland, hypridle, hyprlock, hyprshot, waybar, swaync, grim, slurp, kanshi, swaybg |
| XDG portals | xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk, xdg-desktop-portal-wlr |
| Terminal & shell | ghostty, zsh, zsh-completions, tmux |
| Fonts | ttf-jetbrains-mono-nerd, noto-fonts, noto-fonts-cjk |
| Theming | nwg-look, papirus-icon-theme, gtk-engine-murrine |
| Qt theming | qt5ct, qt6ct, qt5-wayland, qt6-wayland, kvantum, kvantum-qt5 |
| Polkit | polkit-gnome |
| File manager | nemo, gvfs, gvfs-afc, gvfs-mtp, gvfs-smb, ark, loupe, celluloid, evince, gnome-disk-utility, gnome-text-editor |
| Networking | networkmanager, network-manager-applet, wpa_supplicant, firewalld, firewall-config |
| Bluetooth | bluez, bluez-utils, blueman |
| Audio | pipewire-audio, pipewire-pulse, wireplumber, pavucontrol, alsa-firmware, sof-firmware |
| Clipboard | cliphist, wl-clipboard |
| Input method | fcitx5, fcitx5-gtk, fcitx5-qt, fcitx5-configtool, fcitx5-bamboo |
| Media | obs-studio, ffmpeg, cava, playerctl |
| Gaming | gamemode |
| Dev tools | neovim, vim, nano, git, wget, rsync, stow, base-devel, cmake, npm, python-pipx, rustup, github-cli |
| CLI tools | bat, eza, fd, fzf, zoxide, lazygit, lazydocker, fastfetch, htop, btop |
| Security | strace, ltrace, binwalk, checksec, upx |
| Printing | cups, cups-pk-helper, system-config-printer |
| Misc | flatpak, fuse2, dpkg, zram-generator, yad, man-db, unzip, zip, keepass, brightnessctl, libvips |
| Display manager | sddm |

### AUR

| Category | Packages |
|----------|----------|
| Hyprland extras | wlogout, awww, uwsm |
| App launcher | walker, elephant-bin, elephant-desktopapplications-bin, elephant-menus-bin |
| Browser | brave-bin |
| Editor | sublime-text-4 |
| Shell prompt | oh-my-posh |
| Theming | sddm-astronaut-theme, catppuccin-gtk-theme-mocha, catppuccin-qt5ct-git, kvantum-theme-catppuccin-git, ttf-segoe-ui-variable, whitesur-icon-theme, moga-neon-cursor-theme, apple_cursor, tint |
| Wallpaper | waypaper |
| Communication | spotify, localsend |
| Gaming | xpadneo-dkms, balatro-mod-manager-bin |
| Fun CLI | pokemon-colorscripts-git, pipes.sh, cbonsai, cmatrix, ani-cli, ascii, neocities |

## Keybindings

| Key | Action |
|-----|--------|
| `Super + T` | Terminal (Ghostty) |
| `Super + E` | File manager (Nemo) |
| `Super + B` | Browser (Brave) |
| `Super + A` | App launcher (Walker) |
| `Super + V` | Clipboard picker |
| `Super + .` | Emoji picker |
| `Super + L` | Lock screen |
| `Super + H` | Keybinding hints overlay |
| `Super + W` | Toggle floating |
| `Super + Shift + W` | Random wallpaper |
| `Super + Shift + S` | Screenshot (region) |
| `Super + Shift + Ctrl + Esc` | Exit Hyprland |
| `Super + [1–0]` | Switch workspace |
| `Super + Shift + [1–0]` | Move window to workspace |
| Power button | wlogout menu |

## Included Configs

| App | Purpose |
|-----|---------|
| Hyprland | Window manager |
| Waybar | Status bar |
| swaync | Notifications |
| Walker + Elephant | App launcher |
| Ghostty | Terminal |
| Zsh + oh-my-posh | Shell + prompt |
| Neovim | Editor |
| Tmux | Multiplexer |
| wlogout | Logout menu |
| cava | Audio visualizer |
| nwg-look / qt5ct / qt6ct | GTK + Qt theming |
| Kvantum | Qt style engine |
| waypaper | Wallpaper picker (awww backend) |
| mpv | Media player keybindings |

## Structure

```
.
├── .config/
│   ├── cava/
│   ├── fontconfig/
│   ├── ghostty/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── hypr/
│   │   ├── conf/         # Modular config (appearance, keybindings, etc.)
│   │   ├── scripts/      # gtk-settings-watch.sh
│   │   ├── hyprland.conf
│   │   ├── hypridle.conf
│   │   └── hyprlock.conf
│   ├── Kvantum/
│   ├── mpv/
│   ├── nvim/
│   ├── nwg-look/
│   ├── ohmyposh/
│   ├── qt5ct/
│   ├── qt6ct/
│   ├── swaync/
│   ├── viegphunt/        # Scripts (launcher, wallpaper, lock, themes, etc.)
│   ├── walker/
│   ├── waybar/
│   ├── waypaper/
│   └── wlogout/
├── wallpapers/
├── install.sh
├── .zshrc
└── .tmux.conf
```

## Credits

Based on the original dotfiles by [ViegPhunt](https://github.com/ViegPhunt) — check out their work:
- [ViegPhunt/Arch-Hyprland](https://github.com/ViegPhunt/Arch-Hyprland)
- [ViegPhunt/Dotfiles](https://github.com/ViegPhunt/Dotfiles)
