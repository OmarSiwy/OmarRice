#!/usr/bin/bash
set -e  # Exit on error

# Function to print steps
print_step() {
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

# Cache sudo credentials
print_step "Caching sudo credentials"
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

print_step "Testing internet connection"
if ping -c 4 8.8.8.8; then
    echo "Internet connection is working."
else
    echo "Internet connection failed. Please check your network."
    exit 1
fi

print_step "Updating system packages"
pacman -Syu --noconfirm sudo

# Add a new user
print_step "Adding a new user"
read -p "Enter new username: " USERNAME
useradd -m -G wheel,users,storage,power,video,audio,input "$USERNAME"
passwd "$USERNAME"

# Grant sudo privileges by configuring the sudoers file
print_step "Granting sudo access to the new user"
if ! grep -q "^%wheel ALL=(ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL) ALL" | sudo EDITOR='tee -a' visudo
fi

print_step "Switching to the new user"
if [ "$(whoami)" != "$USERNAME" ]; then
    print_step "Switching to the new user"
    
    SCRIPT_PATH=$(realpath "$0")
    cp "$SCRIPT_PATH" /tmp/RiceSetup.sh
    chmod +x /tmp/RiceSetup.sh

    su - "$USERNAME" -c "bash /tmp/RiceSetup.sh"
    
    rm -f /tmp/RiceSetup.sh
    exit 0
fi

# Update system and install Go and xdg-user-dirs
echo "Updating system and installing Go and xdg-user-dirs"
sudo pacman -S xdg-user-dirs --noconfirm
echo "Configuring XDG user directories"
mkdir -p "$HOME/.config" "$HOME/Wallpapers"
xdg-user-dirs-update
echo "Installing yay"
cd "$HOME" && mkdir -p aur
cd aur
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

echo "User environment setup complete."

# Audio and Bluetooth setup
print_step "Installing audio utilities"
sudo pacman -S alsa-utils alsa-plugins --noconfirm
sudo pacman -S pipewire pipewire-alsa pipewire-pulse wireplumber --noconfirm

print_step "Installing Bluetooth utilities"
sudo pacman -S bluez bluez-utils blueman --noconfirm
sudo systemctl enable bluetooth

# Networking setup
print_step "Installing SSH and DHCP utilities"
sudo pacman -S openssh iw wpa_supplicant --noconfirm
sudo systemctl enable sshd
sudo systemctl enable dhcpcd

# Pacman configuration
print_step "Enhancing pacman settings"
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
fi

# Filesystem optimization
print_step "Enabling SSD TRIM"
sudo systemctl enable fstrim.timer

print_step "Setting up NTP (Network Time Protocol)"
sudo pacman -S ntp --noconfirm
sudo systemctl enable ntpd
timedatectl set-ntp true

# Dependencies for GUI and ricing
print_step "Installing Wayland and Hyprland dependencies"
sudo pacman -S hyprland hyprpaper swayidle --noconfirm
yay -S wlogout swaylock-effects-git --noconfirm

# Install appropriate graphics drivers
print_step "Installing graphics drivers"
read -p "Select your GPU type (intel/nvidia/amd): " GPU
case "$GPU" in
    intel)
        sudo pacman -S mesa intel-media-driver libva-intel-driver vulkan-intel --noconfirm
        ;;
    nvidia)
        sudo pacman -S nvidia --noconfirm
        ;;
    amd)
        sudo pacman -S mesa libva-mesa-driver vulkan-radeon --noconfirm
        ;;
    *)
        echo "Invalid GPU type. Skipping graphics driver installation."
        ;;
esac

# Install fonts
print_step "Installing fonts"
sudo pacman -S noto-fonts ttf-opensans ttf-firacode-nerd ttf-jetbrains-mono noto-fonts-emoji --noconfirm

# Install essential applications
print_step "Installing essential applications"
sudo pacman -S alacritty neovim wofi waybar imv firefox hyprshot vlc zathura zathura-pdf-mupdf gammastep --noconfirm

# Enable dark theme
print_step "Setting dark theme for GTK applications"
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Programming tools
print_step "Installing programming tools"
sudo pacman -S rust lua luarocks python python-pip zig --noconfirm

print_step "Installing Rust via rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Digital hardware utilities
print_step "Installing digital hardware tools"
sudo pacman -S icarus-verilog gtkwave --noconfirm

# CLI utilities
print_step "Installing CLI utilities"
sudo pacman -S tldr fzf wget curl tar unzip gzip htop neofetch --noconfirm
yay -S pfetch --noconfirm

# Copy configuration files and wallpapers
print_step "Copying configuration files and wallpapers"
cp -r .config "$HOME/.config"
cp -r .wallpapers "$HOME/Wallpapers"

print_step "Setup complete! Reboot the system to apply all changes."
