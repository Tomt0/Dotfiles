# Tomt0's Dotfiles

Arch Linux desktop — Hyprland · Catppuccin Mocha · Waybar · Walker · SDDM

## Install

Run this from a fresh Arch install (as your regular user, not root):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Tomt0/Dotfiles/main/install.sh)
```

This will:
- Install all packages (pacman + AUR via yay)
- Set up GPU drivers, services, gaming optimizations, zram, SDDM theme
- Clone this repo and apply all configs to the right locations
- Copy wallpapers to `~/Pictures/Wallpapers/`
- Apply the GTK Catppuccin theme

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
| Rofi | Emoji / clipboard picker |
| wlogout | Logout menu |
| cava | Audio visualizer |
| nwg-look / qt6ct | GTK + Qt theming |

## Structure

```
.
├── .config/
│   ├── cava/
│   ├── colors/
│   ├── fontconfig/
│   ├── ghostty/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── hypr/
│   ├── nvim/
│   ├── ohmyposh/
│   ├── qt6ct/
│   ├── rofi/
│   ├── swaync/
│   ├── viegphunt/      # Scripts (launcher, wallpaper, lock, etc.)
│   ├── walker/
│   ├── waybar/
│   └── wlogout/
├── wallpapers/
├── install.sh
├── .zshrc
└── .tmux.conf
```
