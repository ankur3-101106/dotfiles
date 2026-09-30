#!/usr/bin/env bash
# Dotfiles Installation Script for Arch Linux
# 
# This script installs packages and deploys configuration files from this repository.
# 
# Usage:
#   ./install.sh           # Full installation
#   ./install.sh --dry-run # Show what would be done without making changes
#   ./install.sh --help    # Show this help message

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# Configuration
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
FORCE=false
SKIP_PACKAGES=false
SKIP_CONFIGS=false

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        eval "$@"
    fi
}

# Check if running on Arch Linux
check_arch() {
    if [ ! -f /etc/arch-release ] && ! grep -q "^ID=arch$" /etc/os-release 2>/dev/null; then
        log_error "This script is designed for Arch Linux only."
        log_error "Detected: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
        exit 1
    fi
    log_success "Arch Linux detected"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect AUR helper
detect_aur_helper() {
    if command_exists yay; then
        echo "yay"
    elif command_exists paru; then
        echo "paru"
    elif command_exists pikaur; then
        echo "pikaur"
    elif command_exists aurman; then
        echo "aurman"
    elif command_exists trizen; then
        echo "trizen"
    else
        echo ""
    fi
}

# Install packages from pacman
install_pacman_packages() {
    local package_file="$DOTFILES_DIR/packages/pacman.txt"
    
    if [ ! -f "$package_file" ]; then
        log_warn "Package file not found: $package_file"
        return 0
    fi

    log_info "Installing official Arch packages..."
    
    # Read packages, skip comments and empty lines
    local packages=()
    while IFS= read -r line; do
        line="${line%%#*}"  # Remove comments
        line="${line// /}"  # Remove spaces
        if [ -n "$line" ]; then
            packages+=("$line")
        fi
    done < "$package_file"

    if [ ${#packages[@]} -eq 0 ]; then
        log_info "No packages to install from $package_file"
        return 0
    fi

    # Check which packages are already installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            log_info "Already installed: $pkg"
        else
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        log_success "All official packages already installed"
        return 0
    fi

    log_info "Installing ${#to_install[@]} packages: ${to_install[*]}"
    run_cmd sudo pacman -S --needed --noconfirm "${to_install[@]}"
    log_success "Official packages installed"
}

# Install packages from AUR
install_aur_packages() {
    local package_file="$DOTFILES_DIR/packages/aur.txt"
    
    if [ ! -f "$package_file" ]; then
        log_warn "AUR package file not found: $package_file"
        return 0
    fi

    local aur_helper
    aur_helper=$(detect_aur_helper)
    
    if [ -z "$aur_helper" ]; then
        log_warn "No AUR helper found (yay, paru, pikaur, aurman, trizen). Skipping AUR packages."
        log_warn "Install an AUR helper first, then re-run this script."
        return 0
    fi

    log_info "Using AUR helper: $aur_helper"

    # Read packages, skip comments and empty lines
    local packages=()
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line// /}"
        if [ -n "$line" ]; then
            packages+=("$line")
        fi
    done < "$package_file"

    if [ ${#packages[@]} -eq 0 ]; then
        log_info "No AUR packages to install"
        return 0
    fi

    # Check which packages are already installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            log_info "Already installed: $pkg"
        else
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        log_success "All AUR packages already installed"
        return 0
    fi

    log_info "Installing ${#to_install[@]} AUR packages: ${to_install[*]}"
    run_cmd "$aur_helper" -S --needed --noconfirm "${to_install[@]}"
    log_success "AUR packages installed"
}

# Create backup of existing config
backup_config() {
    local src="$1"
    local dest_dir="$2"
    
    if [ -e "$src" ] && [ ! -L "$src" ]; then
        local rel_path="${src#$HOME/}"
        local backup_path="$dest_dir/$rel_path"
        local backup_dir
        backup_dir=$(dirname "$backup_path")
        
        run_cmd mkdir -p "$backup_dir"
        run_cmd cp -r "$src" "$backup_path"
        log_info "Backed up: $src -> $backup_path"
    elif [ -L "$src" ]; then
        local target
        target=$(readlink "$src")
        log_info "Skipping symlink: $src -> $target"
    fi
}

# Deploy configurations
deploy_configs() {
    log_info "Deploying configurations..."
    
    # Create backup directory
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi

    # Config directories to deploy
    local config_dirs=(
        "niri"
        "hypr"
        "caelestia"
        "quickshell"
        "rofi"
        "fastfetch"
        "waybar"
        "gtk-3.0"
        "gtk-4.0"
        "kitty"
        "ghostty"
        "foot"
        "alacritty"
        "swaync"
        "wallust"
        "fuzzel"
        "nwg-displays"
        "qt5ct"
        "qt6ct"
    )

    # Deploy .config directories
    for dir in "${config_dirs[@]}"; do
        local src="$DOTFILES_DIR/.config/$dir"
        local dest="$HOME/.config/$dir"
        
        if [ -d "$src" ]; then
            # Backup existing config
            if [ -e "$dest" ] || [ -L "$dest" ]; then
                backup_config "$dest" "$BACKUP_DIR/.config"
            fi
            
            # Create parent directory
            run_cmd mkdir -p "$(dirname "$dest")"
            
            # Deploy (copy for now, can be changed to symlink)
            log_info "Deploying: $dir"
            run_cmd cp -r "$src" "$dest"
        else
            log_warn "Source not found: $src"
        fi
    done

    # Deploy individual config files in .config
    local config_files=(
        "starship.toml"
    )

    for file in "${config_files[@]}"; do
        local src="$DOTFILES_DIR/.config/$file"
        local dest="$HOME/.config/$file"
        
        if [ -f "$src" ]; then
            if [ -e "$dest" ] && [ ! -L "$dest" ]; then
                backup_config "$dest" "$BACKUP_DIR/.config"
            fi
            run_cmd mkdir -p "$(dirname "$dest")"
            log_info "Deploying: $file"
            run_cmd cp "$src" "$dest"
        fi
    done

    # Deploy .bashrc
    local bashrc_src="$DOTFILES_DIR/.bashrc"
    local bashrc_dest="$HOME/.bashrc"
    
    if [ -f "$bashrc_src" ]; then
        if [ -e "$bashrc_dest" ] && [ ! -L "$bashrc_dest" ]; then
            backup_config "$bashrc_dest" "$BACKUP_DIR"
        fi
        log_info "Deploying: .bashrc"
        run_cmd cp "$bashrc_src" "$bashrc_dest"
    fi

    log_success "Configurations deployed"
    if [ "$DRY_RUN" = false ]; then
        log_info "Backups saved to: $BACKUP_DIR"
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    local dirs=(
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.local/share"
        "$HOME/.local/state"
        "$HOME/.cache"
        "$HOME/Pictures/Screenshots"
        "$HOME/Pictures/Wallpapers"
        "$HOME/Projects"
        "$HOME/Downloads"
        "$HOME/Documents"
    )

    for dir in "${dirs[@]}"; do
        run_cmd mkdir -p "$dir"
    done
    
    log_success "Directories created"
}

# Setup git config if needed
setup_git() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    if ! git config --global user.name >/dev/null 2>&1; then
        log_warn "Git user.name not set. Please run:"
        echo "  git config --global user.name \"Your Name\""
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        log_warn "Git user.email not set. Please run:"
        echo "  git config --global user.email \"your@email.com\""
    fi
}

# Post-installation steps
post_install() {
    log_info "Running post-installation steps..."
    
    # Update font cache
    if command_exists fc-cache; then
        run_cmd fc-cache -fv
        log_success "Font cache updated"
    fi
    
    # Update desktop database
    if command_exists update-desktop-database; then
        run_cmd update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    # Reload systemd user units
    if command_exists systemctl; then
        run_cmd systemctl --user daemon-reload 2>/dev/null || true
    fi
    
    log_success "Post-installation complete"
}

# Print usage
usage() {
    cat << USAGE
Dotfiles Installation Script for Arch Linux

Usage: $0 [OPTIONS]

OPTIONS:
    --dry-run       Show what would be done without making changes
    --force         Force overwrite without prompting
    --skip-packages Skip package installation
    --skip-configs  Skip configuration deployment
    --help          Show this help message

EXAMPLES:
    $0                  # Full installation
    $0 --dry-run        # Preview changes
    $0 --skip-packages  # Only deploy configs
    $0 --skip-configs   # Only install packages

USAGE
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --skip-packages)
            SKIP_PACKAGES=true
            shift
            ;;
        --skip-configs)
            SKIP_CONFIGS=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main installation flow
main() {
    echo "=========================================="
    echo "  Arch Linux Dotfiles Installation"
    echo "=========================================="
    echo ""
    
    check_arch
    
    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    create_directories
    
    if [ "$SKIP_PACKAGES" = false ]; then
        install_pacman_packages
        install_aur_packages
    else
        log_info "Skipping package installation"
    fi
    
    if [ "$SKIP_CONFIGS" = false ]; then
        deploy_configs
    else
        log_info "Skipping configuration deployment"
    fi
    
    setup_git
    post_install
    
    echo ""
    echo "=========================================="
    if [ "$DRY_RUN" = true ]; then
        echo "  DRY RUN COMPLETE"
    else
        echo "  INSTALLATION COMPLETE"
    fi
    echo "=========================================="
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc"
    echo "  2. Log out and back in for Wayland compositor changes"
    echo "  3. Run 'fastfetch' to verify the setup"
    echo "  4. Configure your monitors with 'nwg-displays' if needed"
    echo ""
    
    if [ "$DRY_RUN" = false ] && [ -d "$BACKUP_DIR" ]; then
        log_info "Your previous configs are backed up at: $BACKUP_DIR"
    fi
}

main "$@"
