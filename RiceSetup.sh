#!/usr/bin/bash
set -e

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
sudo pacman -Syu --noconfirm sudo

# Add a new user
print_step "Adding a new user"
read -p "Enter new username: " USERNAME
sudo useradd -m -G wheel,users,storage,power,video,audio,input "$USERNAME"
sudo passwd "$USERNAME"

# Grant sudo privileges by configuring the sudoers file
print_step "Granting sudo access to the new user"
if ! grep -q "^%wheel ALL=(ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL) ALL" | sudo EDITOR='tee -a' visudo
fi

# System-wide installations (run as root)
print_step "Performing system-wide installations"

# Install GPU drivers
echo "Select your GPU type (intel/nvidia/amd):"
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

# Install core system utilities and packages
print_step "Installing system utilities and core tools"
sudo pacman -S xdg-user-dirs alsa-utils alsa-plugins pipewire pipewire-alsa pipewire-pulse wireplumber \
openssh iw wpa_supplicant ntp tldr fzf wget curl tar unzip gzip htop neofetch --noconfirm

# Network and Bluetooth
sudo pacman -S bluez bluez-utils blueman --noconfirm
sudo systemctl enable bluetooth
sudo systemctl enable sshd
sudo systemctl enable dhcpcd

# Fonts
print_step "Installing fonts"
sudo pacman -S noto-fonts ttf-opensans ttf-firacode-nerd ttf-jetbrains-mono noto-fonts-emoji --noconfirm

# Ricing:
print_step "Installing GUI and ricing dependencies"
sudo pacman -S alacritty neovim wofi waybar imv firefox gammastep lsd --noconfirm

# Media
print_step "Installing media and productivity tools"
sudo pacman -S vlc zathura zathura-pdf-mupdf --noconfirm

# Programming
print_step "Installing programming and development tools"
sudo pacman -S rust lua luarocks python python-pip zig --noconfirm
sudo pacman -S fd ripgrep bat eza tree-sitter tree-sitter-cli --noconfirm

# Digital Hardware/Simulation
print_step "Installing digital hardware and simulation tools"
sudo pacman -S gtkwave --noconfirm

# Enable necessary services
print_step "Enabling necessary services"
sudo systemctl enable fstrim.timer
sudo systemctl enable ntpd
timedatectl set-ntp true

# User-specific setup
print_step "Setting up user-specific environment for $USERNAME"
runuser -l "$USERNAME" <<EOF
  export HOME="/home/$USERNAME"
  export USER="$USERNAME"

  # Create user directories
  echo "Configuring XDG user directories"
  mkdir -p "\$HOME/.config" "\$HOME/Wallpapers"
  xdg-user-dirs-update

  # Install yay (AUR helper)
  echo "Installing yay"
  cd "\$HOME" && mkdir -p aur
  cd aur
  if [ ! -d yay ]; then
    git clone https://aur.archlinux.org/yay.git
  else
    echo "Yay repository already exists. Skipping."
  fi
  cd yay
  makepkg -si --noconfirm

  # Install Yay packages
  yay -S hyprshot wlogout swaylock-effects-git pfetch --noconfirm
  yay -S iverilog --noconfirm

  # Apply user-specific configurations
  echo "Moving user-specific configurations"
  if [ -d /root/.config ]; then
    mv /root/.config "\$HOME/.config"
  else
    echo "No .config directory found in /root. Skipping."
  fi

  if [ -d /root/.wallpapers ]; then
    mv /root/.wallpapers "\$HOME/.wallpapers"
  else
    echo "No .wallpapers directory found in /root. Skipping."
  fi

  if [ -f /root/.bashrc ]; then
    mv /root/.bashrc "\$HOME/.bashrc"
  else
    echo "No .basrc file found in /root. Skipping."
  fi
EOF


# Final message and optional user switch
print_step "Setup complete!"
su - "$USERNAME"

sudo reboot
