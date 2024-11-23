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

# Select GPU type as the new user (direct command approach)
print_step "Switching to the new user for GPU selection and setup"
GPU=$(su - "$USERNAME" -c '
    echo "Select your GPU type (intel/nvidia/amd):"
    read GPU
    echo $GPU
')

case "$GPU" in
    intel)
        print_step "Installing Intel GPU drivers"
        su - "$USERNAME" -c "sudo pacman -S mesa intel-media-driver libva-intel-driver vulkan-intel --noconfirm"
        ;;
    nvidia)
        print_step "Installing NVIDIA GPU drivers"
        su - "$USERNAME" -c "sudo pacman -S nvidia --noconfirm"
        ;;
    amd)
        print_step "Installing AMD GPU drivers"
        su - "$USERNAME" -c "sudo pacman -S mesa libva-mesa-driver vulkan-radeon --noconfirm"
        ;;
    *)
        print_step "Invalid GPU type selected. Skipping GPU driver installation."
        ;;
esac

print_step "Switching to the new user and setting up environment"
su - "$USERNAME" <<'EOF'
  echo "Setting up user environment..."

  # Update system and install Go and xdg-user-dirs
  echo "Updating system and installing Go and xdg-user-dirs"
  sudo pacman -S xdg-user-dirs --noconfirm
  mkdir -p "$HOME/.config" "$HOME/Wallpapers"
  xdg-user-dirs-update

  # Install yay (AUR helper)
  echo "Installing yay"
  cd "$HOME" && mkdir -p aur
  cd aur
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm

  echo "User environment setup complete."

  # Audio and Bluetooth setup
  sudo pacman -S alsa-utils alsa-plugins --noconfirm
  sudo pacman -S pipewire pipewire-alsa pipewire-pulse wireplumber --noconfirm
  sudo pacman -S bluez bluez-utils blueman --noconfirm
  sudo systemctl enable bluetooth

  # Networking setup
  sudo pacman -S openssh iw wpa_supplicant --noconfirm
  sudo systemctl enable sshd
  sudo systemctl enable dhcpcd

  # Pacman configuration
  sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
  if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
  fi

  # Filesystem optimization
  sudo systemctl enable fstrim.timer

  # NTP setup
  sudo pacman -S ntp --noconfirm
  sudo systemctl enable ntpd
  timedatectl set-ntp true

  # Dependencies for GUI and ricing
  sudo pacman -S hyprland hyprpaper swayidle --noconfirm
  yay -S wlogout swaylock-effects-git --noconfirm

  # Install fonts
  sudo pacman -S noto-fonts ttf-opensans ttf-firacode-nerd ttf-jetbrains-mono noto-fonts-emoji --noconfirm

  # Install essential applications
  sudo pacman -S alacritty neovim wofi waybar imv firefox hyprshot vlc zathura zathura-pdf-mupdf gammastep --noconfirm

  # Enable dark theme
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  # Programming tools
  sudo pacman -S rust lua luarocks python python-pip zig --noconfirm
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  source $HOME/.cargo/env

  # Digital hardware utilities
  sudo pacman -S icarus-verilog gtkwave --noconfirm

  # CLI utilities
  sudo pacman -S tldr fzf wget curl tar unzip gzip htop neofetch --noconfirm
  yay -S pfetch --noconfirm

  # Copy configuration files and wallpapers
  cp -r .config "$HOME/.config"
  cp -r .wallpapers "$HOME/Wallpapers"

  echo "Setup complete for user $USER! Please reboot the system."
EOF
