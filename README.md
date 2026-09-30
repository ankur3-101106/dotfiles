# Arch Linux Dotfiles - Personal Takeaway

A clean, reproducible, and maintainable dotfiles repository for Arch Linux with Hyprland/Niri, Caelestia/Quickshell, and modern CLI tools.

## Quick Start

```bash
git clone https://github.com/ankur3-101106/dotfiles.git
cd dotfiles
./install.sh
```

## Supported Environment

- **OS**: Arch Linux (and Arch-based distributions)
- **Window Managers**: Hyprland, Niri
- **Shell**: Bash (with Starship prompt), Fish, Zsh
- **Terminals**: Kitty, Ghostty, Foot, Alacritty
- **Bar**: Waybar
- **Launcher**: Rofi (Wayland)
- **Notifications**: SwayNC
- **Theming**: Wallust, Caelestia, GTK3/4, Qt5/6

## Repository Structure

```
dotfiles/
├── .config/                    # XDG configuration directories
│   ├── niri/                   # Niri scrollable-tiling WM config
│   ├── hypr/                   # Hyprland dynamic tiling WM config
│   │   ├── hyprland/           # Modular Hyprland config (lua)
│   │   ├── scheme/             # Color schemes
│   │   ├── utils/              # Utility functions
│   │   └── wallust/            # Wallust integration
│   ├── caelestia/              # Caelestia shell config (Quickshell)
│   ├── quickshell/             # Quickshell modules & overview
│   ├── rofi/                   # Rofi launcher config & themes
│   ├── fastfetch/              # Fastfetch system info configs
│   ├── waybar/                 # Waybar status bar config
│   │   ├── configs/            # Multiple bar layouts
│   │   ├── style/              # CSS themes
│   │   └── wallust/            # Wallust-generated colors
│   ├── gtk-3.0/                # GTK3 theming
│   ├── gtk-4.0/                # GTK4 theming
│   ├── kitty/                  # Kitty terminal config
│   ├── ghostty/                # Ghostty terminal config
│   ├── foot/                   # Foot terminal config
│   ├── alacritty/              # Alacritty terminal config
│   ├── swaync/                 # SwayNC notification center
│   ├── wallust/                # Wallust color generator
│   ├── fuzzel/                 # Fuzzel launcher (backup)
│   ├── nwg-displays/           # Display configuration tool
│   ├── qt5ct/                  # Qt5 theming
│   └── qt6ct/                  # Qt6 theming
├── .bashrc                     # Bash configuration
├── starship.toml               # Starship prompt config
├── packages/
│   ├── pacman.txt              # Official Arch packages
│   └── aur.txt                 # AUR packages
├── install.sh                  # Main installation script
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## Installation

### Prerequisites

- Arch Linux (or Arch-based: EndeavourOS, Manjaro, Garuda, etc.)
- Internet connection
- `sudo` privileges

### Options

```bash
# Full installation (packages + configs)
./install.sh

# Preview what would be done (no changes)
./install.sh --dry-run

# Only install packages
./install.sh --skip-configs

# Only deploy configurations
./install.sh --skip-packages

# Force overwrite without prompts
./install.sh --force
```

### What the installer does

1. **Detects Arch Linux** - Exits safely on other distributions
2. **Creates directories** - XDG directories, screenshots, projects, etc.
3. **Installs packages** - Official (pacman) and AUR (yay/paru/pikaur)
4. **Backs up existing configs** - To `~/.dotfiles-backup-YYYYMMDD-HHMMSS/`
5. **Deploys configurations** - Copies configs to `~/.config/`
6. **Sets up Starship, Zoxide, FZF** - Shell integrations
7. **Updates font cache & desktop database**

## Package Management

### Official Packages (`packages/pacman.txt`)

Core packages for the desktop environment:
- Window managers: `hyprland`, `niri`
- Wayland tools: `waybar`, `rofi-wayland`, `swaync`, `hypridle`, `hyprlock`
- Terminals: `kitty`, `ghostty`, `foot`, `alacritty`
- CLI tools: `starship`, `zoxide`, `fzf`, `bat`, `eza`, `ripgrep`, `fd`, `btop`, `fastfetch`
- Development: `git`, `github-cli`, `neovim`, `lazygit`, `docker`, `rustup`, `go`, `nodejs`, `python`
- Fonts: `ttf-jetbrains-mono-nerd`, `noto-fonts*`
- Theming: `qt5ct`, `qt6ct`, `kvantum`, `wallust`, `swww`, `grim`, `slurp`
- Audio: `pipewire`, `wireplumber`, `pavucontrol`, `playerctl`, `cava`

### AUR Packages (`packages/aur.txt`)

Additional packages not in official repos:
- `caelestia-git`, `quickshell-git` - Shell components
- `atuin`, `navi`, `chezmoi` - Shell enhancements
- `visual-studio-code-bin`, `github-desktop-bin` - Development
- `spotify`, `brave-bin`, `zen-browser-bin` - Applications
- `auto-cpufreq`, `tlp` - Power management

### Installing packages manually

```bash
# Official packages
sudo pacman -S --needed - < packages/pacman.txt

# AUR packages (requires yay/paru)
yay -S --needed - < packages/aur.txt
```

## Configuration Deployment

### Symlink vs Copy

The installer **copies** files by default (not symlinks) for safety and simplicity. This means:
- Changes to `~/.config/` won't automatically sync back to the repo
- To update the repo: copy files back manually or use a tool like `chezmoi`
- To update the system: re-run `./install.sh`

To use symlinks instead, modify `install.sh` to use `ln -sf` instead of `cp -r`.

### Machine-Specific Configuration

Some configs contain machine-specific settings (monitor layouts, GPU settings, etc.):

| Config | Machine-Specific Files | Handling |
|--------|------------------------|----------|
| Niri | `monitor.kdl` | Excluded from repo; generate with `nwg-displays` |
| Hyprland | `monitors.conf`, `monitors.lua` | Excluded; use `hyprctl monitors` or `nwg-displays` |
| Caelestia | `monitors/eDP-1/shell.json` | Excluded; per-monitor config |
| GTK | `bookmarks`, `servers` | Excluded; user-specific paths |

**After installation**, configure your displays:
```bash
# For Hyprland/Niri
nwg-displays

# For Hyprland specifically
hyprctl monitors
```

## Updating & Restoring

### Pull latest changes

```bash
cd ~/dotfiles
git pull
./install.sh
```

### Restore from backup

```bash
# List available backups
ls -la ~/.dotfiles-backup-*

# Restore a specific backup
cp -r ~/.dotfiles-backup-YYYYMMDD-HHMMSS/.config/* ~/.config/
cp ~/.dotfiles-backup-YYYYMMDD-HHMMSS/.bashrc ~/.bashrc
```

### Add new application config

1. Copy config to repo:
   ```bash
   cp -r ~/.config/newapp ~/dotfiles/.config/
   ```
2. Add to `install.sh` config_dirs array
3. Commit and push:
   ```bash
   git add .config/newapp
   git commit -m "feat: add newapp configuration"
   git push
   ```

## Uninstall / Revert

```bash
# Restore from latest backup
BACKUP=$(ls -dt ~/.dotfiles-backup-* | head -1)
cp -r "$BACKUP/.config/"* ~/.config/
cp "$BACKUP/.bashrc" ~/.bashrc

# Remove installed packages (optional)
# sudo pacman -Rns $(cat packages/pacman.txt)
# yay -Rns $(cat packages/aur.txt)
```

## Dependencies & Assumptions

- **AUR Helper**: `yay` preferred (also supports `paru`, `pikaur`, `aurman`, `trizen`)
- **Display Server**: Wayland (Hyprland/Niri)
- **Shell**: Bash as default (Fish/Zsh configs not managed)
- **GPU**: Configs work with AMD/Intel/NVIDIA (NVIDIA may need extra setup)
- **Fonts**: Nerd Fonts required for icons (JetBrainsMono Nerd Font)

## Troubleshooting

### Hyprland/Niri won't start
```bash
# Check logs
journalctl --user -u hyprland -f
journalctl --user -u niri -f

# Verify GPU drivers
lspci -k | grep -A3 -i vga
```

### Waybar not showing
```bash
# Test config
waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css
```

### Starship not working
```bash
# Verify installation
starship --version
# Check shell init
grep starship ~/.bashrc
```

### Missing icons
```bash
# Reinstall fonts
sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts-emoji
fc-cache -fv
```

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgments

- [Hyprland](https://hyprland.org/) - Dynamic tiling Wayland compositor
- [Niri](https://niri-wm.github.io/) - Scrollable-tiling Wayland compositor
- [Caelestia](https://github.com/caelestia-shell/caelestia) - Quickshell-based shell
- [Quickshell](https://github.com/quickshell/quickshell) - QML-based Wayland shell
- [Waybar](https://github.com/Alexays/Waybar) - Highly customizable Wayland bar
- [Wallust](https://github.com/explosion-mental/wallust) - Color palette generator
- [Starship](https://starship.rs/) - Cross-shell prompt
