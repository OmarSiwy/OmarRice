#!/bin/bash
set -e

# ============================================================
# Function Definitions
# ============================================================

STEPS=()
print_step() {
    local step_title="$1"
    STEPS+=("$step_title")
    
    clear # Clear the terminal
    
    # Print the Steps
    echo "Steps:"
    for step in "${STEPS[@]}"; do
        echo "  - $step"
    done
    echo
    
    # Print a separator
    echo "------------------------------------------------------------"
    echo "$step_title"
    echo "------------------------------------------------------------"
}

USERNAME=${SUDO_USER:-$USER}
USER_HOME=/home/$USERNAME
YAY_DIR="$USER_HOME/aur/yay"
SNAP_DIR="$USER_HOME/aur/snap"

chown -R "$USERNAME:$USERNAME" "$YAY_DIR"
chown -R "$USERNAME:$USERNAME" "$SNAP_DIR"

# ============================================================
# Initial Setup
# ============================================================

print_step "Caching sudo credentials"
sudo -v
while true; do
    sudo -n true
    sleep 300
    kill -0 "$$" || exit
done 2>/dev/null &
trap 'kill %1 2>/dev/null || true' EXIT

# ============================================================
# Network Check 
# ============================================================

print_step "Testing internet connection"
if ping -c 4 8.8.8.8; then
    echo "Internet connection is working."
else
    echo "Internet connection failed. Please check your network."
    exit 1
fi

# ============================================================
# System Update
# ============================================================

print_step "Updating system packages"
sudo pacman -Syu --noconfirm sudo

# ============================================================
# Drivers Installation
# ============================================================
print_step "Select your GPU type (intel/nvidia/amd):"
read GPU
case "$GPU" in
    intel)
        print_step "Installing Intel GPU drivers"
        sudo pacman -S mesa intel-media-driver libva-intel-driver vulkan-intel --noconfirm
        ;;
    nvidia)
        print_step "Installing NVIDIA GPU drivers"
        sudo pacman -S nvidia --noconfirm
        ;;
    amd)
        print_step "Installing AMD GPU drivers"
        sudo pacman -S mesa libva-mesa-driver vulkan-radeon --noconfirm
        ;;
    *)
        print_step "Invalid GPU type selected. Skipping GPU driver installation."
        ;;
esac

# ============================================================
# Core System Utilities
# ============================================================

print_step "Installing core system utilities"
sudo pacman -S openssh iw wpa_supplicant ntp tldr fzf wget curl tar unzip gzip htop neofetch cmake --noconfirm
sudo systemctl enable sshd
sudo systemctl enable dhcpcd

print_step "Enabling Optimizations"
sudo systemctl enable fstrim.timer
sudo systemctl enable ntpd
timedatectl set-ntp true

print_step "Network and Bluetooth"
sudo pacman -S xdg-user-dirs alsa-utils alsa-plugins pipewire pipewire-alsa pipewire-pulse wireplumber --noconfirm
sudo pacman -S bluez bluez-utils blueman --noconfirm
sudo systemctl enable bluetooth

print_step "Setting up YAY Package Manager"
USER_HOME=/home/$USERNAME

# Set up YAY (AUR helper)
echo "Installing yay"
if [ ! -d "$YAY_DIR" ]; then
    git clone https://aur.archlinux.org/yay.git "$YAY_DIR"
fi
cd "$YAY_DIR" && makepkg -si --noconfirm

# Set up SNAP (AUR helper)
echo "Installing Snapd"
if [ ! -d "$SNAP_DIR" ]; then
  git clone https://aur.archlinux.org/snapd.git "$SNAP_DIR"
fi
cd "$SNAP_DIR" && makepkg -si --noconfirm
sudo systemctl enable --now snapd.socket
sudo systemctl enable --now snapd.apparmor.service
if [ ! -L /snap ]; then
    sudo ln -s /var/lib/snapd/snap /snap
fi

echo "Configuring XDG user directories"
mkdir -p "$USER_HOME/.config" "$USER_HOME/Wallpapers"
xdg-user-dirs-update --force

echo "Setting up BASH preexec"
if [ ! -d "$USER_HOME/.bash-preexec" ]; then
  git clone https://github.com/rcaloras/bash-preexec.git "$USER_HOME/.bash-preexec"
else
  echo "BASH preexec already exists. Skipping."
fi

print_step "Checking and enabling [multilib] repository in /etc/pacman.conf"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo bash -c 'cat <<EOF >> /etc/pacman.conf

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF'
    print_step "Successfully appended [multilib] to /etc/pacman.conf"
else
    print_step "[multilib] section is already enabled. No changes made."
fi
sudo pacman -Syy --noconfirm

# ============================================================
# GUI and Ricing Setup
# ============================================================

print_step "Installing fonts"
sudo pacman -S noto-fonts ttf-opensans ttf-firacode-nerd ttf-jetbrains-mono noto-fonts-emoji --noconfirm

print_step "Installing GUI and ricing dependencies"
sudo pacman -S base-devel hyprland hyprpaper swayidle python-pillow --noconfirm
sudo pacman -S alacritty neovim wofi waybar imv firefox gammastep lsd notification-daemon xdg-desktop-portal-gtk --noconfirm
yay -S --noconfirm --needed hyprshot wlogout swaylock-effects-git pfetch --noconfirm

RANGER_PLUGINS_DIR="$USER_HOME/.config/ranger/plugins"
mkdir -p "$(dirname "$RANGER_PLUGINS_DIR")"
if [ ! -d "$RANGER_PLUGINS_DIR" ]; then
    git clone https://github.com/alexanderjeurissen/ranger_devicons.git $RANGER_PLUGINS_DIR
fi

sudo pacman -S python-pynvim --noconfirm

print_step "Setting up Notifications"
SERVICE_FILE="/usr/share/dbus-1/services/org.freedesktop.Notifications.service"
SERVICE_CONTENT="[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib/notification-daemon-1.0/notification-daemon"
echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null

# ============================================================
# Media and Productivity Tools
# ============================================================

print_step "Installing media and productivity tools"
sudo pacman -S vlc zathura zathura-pdf-mupdf steam --noconfirm

# Note Taking
sudo pacman -S syncthing --noconfirm
sudo snap install obsidian --classic

# ============================================================
# Analog Hardware CAD Installation
# ============================================================

print_step "Installing Wine and 64-bit libraries"
sudo pacman -Syy wine wine-mono wine-gecko winetricks --noconfirm

# ============================================================
# Kicad
# ============================================================
print_step "Installing KiCAD"
sudo pacman -Syu kicad --noconfirm

# ============================================================
# LTSpice
# ============================================================
print_step "Installing LTSpice via yay"
yay -S wine-ltspice

# ============================================================
# Digital Hardware CAD Installation
# ============================================================

print_step "Installing digital hardware tools and dependencies"
sudo pacman -S gtkwave --noconfirm
yay -S iverilog --noconfirm

# ============================================================
# Programming and Development Tools
# ============================================================

print_step "Installing programming and development tools"
sudo pacman -S rust lua luarocks python python-pip zig --noconfirm
sudo pacman -S fd ripgrep bat eza tree-sitter tree-sitter-cli bash-completion --noconfirm

# ============================================================
# User-Specific Environment Setup
# ============================================================

print_step "Setting up config files for $USERNAME"
CONFIG_DIRS=(.config .wallpapers .bashrc .XResources)
for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$dir" ] || [ -f "$dir" ]; then
    cp -r "$dir" "$USER_HOME/"
  fi
done

# ============================================================
# Finalization
# ============================================================
print_step "Setup complete!"
print_step "Refer to Post-Install Setup"
sudo reboot
