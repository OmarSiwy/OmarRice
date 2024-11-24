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

# ============================================================
# Initial Setup
# ============================================================

print_step "Caching sudo credentials"
sudo -v
while true; do
    sudo -n true
    sleep 120
    kill -0 "$$" || exit
done 2>/dev/null &

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
# User Configuration
# ============================================================

print_step "User Creation"
read -p "Do you want to create a new user? (y/n): " CREATE_USER

if [[ "$CREATE_USER" =~ ^[Yy]$ ]]; then
  print_step "Adding a new user"
  read -p "Enter new username: " USERNAME
  sudo useradd -m -G wheel,users,storage,power,video,audio,input "$USERNAME"
  sudo passwd "$USERNAME"

  # Save the last username to a file
  echo "$USERNAME" | sudo tee /var/log/last_username > /dev/null

  # Grant sudo privileges by configuring the sudoers file
  print_step "Granting sudo access to the new user"
  if ! grep -q "^%wheel ALL=(ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL) ALL" | sudo EDITOR='tee -a' visudo
  fi
else
  USERNAME=$(cat /var/log/last_username)
  if [ -z "$USERNAME" ]; then
    print_step "No user found. Exiting."
    exit 1
  fi
  print_step "Skipping user creation."
fi

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
sudo pacman -S openssh iw wpa_supplicant ntp tldr fzf wget curl tar unzip gzip htop neofetch --noconfirm
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
sudo -u "$USERNAME" bash <<EOF
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
EOF

print_step "Setting up BASH and Directories"
sudo -u "$USERNAME" bash <<EOF
  # Create user directories
  echo "Configuring XDG user directories"
  mkdir -p "\$HOME/.config" "\$HOME/Wallpapers"
  xdg-user-dirs-update

  # BASH SETUP
  git clone https://github.com/rcaloras/bash-preexec.git ~/.bash-preexec
EOF

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
sudo -u "$USERNAME" bash <<EOF
  yay -S hyprshot wlogout swaylock-effects-git pfetch --noconfirm
EOF

print_step "Setting up Ranger Devicons"
if [ ! -d ~/.config/ranger/plugins ]; then
  git clone https://github.com/alexanderjeurissen/ranger_devicons.git ~/.config/ranger/plugins/ranger_devicons
fi
sudo pacman -S python-pynvim --noconfirm

print_step "Setting up Notifications"
SERVICE_FILE="/usr/share/dbus-1/services/org.freedesktop.Notifications.service"
SERVICE_CONTENT="[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib/notification-daemon-1.0/notification-daemon"
echo "$SERVICE_CONTENT" > "$SERVICE_FILE"

# ============================================================
# Media and Productivity Tools
# ============================================================

print_step "Installing media and productivity tools"
sudo pacman -S vlc zathura zathura-pdf-mupdf steam --noconfirm

# Note Taking
sudo pacman -S syncthing --noconfirm
sudo -u "$USERNAME" bash <<EOF
  git clone https://aur.archlinux.org/snapd.git
  cd snapd
  makepkg -si
  sudo systemctl enable --now snapd.socket
  sudo systemctl enable --now snapd.apparmor.service
  sudo ln -s /var/lib/snapd/snap /snap
  sudo snap install obsidian --classic
EOF

# ============================================================
# Analog Hardware CAD Installation
# ============================================================

print_step "Installing Wine and 32-bit libraries"
sudo pacman -Syy wine wine-mono wine-gecko winetricks --noconfirm
sudo pacman -S lib32-libx11 lib32-alsa-lib lib32-libpulse lib32-fontconfig lib32-mesa --noconfirm

# ============================================================
# Altium Designer installation
# ============================================================

export WINEPREFIX=/home/$USERNAME/Altium
export WINEARCH=win32

print_step "Installing required components via Winetricks"
sudo -u "$USERNAME" WINEPREFIX=$WINEPREFIX winetricks gdiplus corefonts riched20 mdac28 msxml6 dotnet48 || {
    echo "Winetricks failed. Please check the error and try again."
    exit 1
}

print_step "Opening Wine Configuration (winecfg)"
sudo -u "$USERNAME" WINEPREFIX=$WINEPREFIX winecfg

print_step "Installing Altium Designer"
echo "Please provide your AltiumLive credentials."
read -p "Enter your AltiumLive email: " ALTIUM_EMAIL
read -s -p "Enter your AltiumLive password (input hidden): " ALTIUM_PASSWORD
echo

sudo -u "$USERNAME" WINEPREFIX=$WINEPREFIX wine ./Altium/AltiumDesignerSetup_25_0_2.exe \
  -Programs:"C:\\Program Files\\Altium\\AD25" \
  -Documents:"C:\\Users\\Public\\Documents\\Altium\\AD25" \
  -UI:None \
  -AutoInstall \
  -InstallAll \
  -User:"$ALTIUM_EMAIL" \
  -Password:"$ALTIUM_PASSWORD" || {
    echo "Altium Designer installation failed. Please check the error and try again."
    exit 1
}

print_step "Packaging Altium Designer"
sudo -u "$USERNAME" bash <<EOF
mkdir -p ~/Applications
cat <<LAUNCHER > ~/Applications/AltiumDesigner.sh
#!/usr/bin/bash
export WINEPREFIX=/home/$USERNAME/Altium
wine /home/$USERNAME/Altium/drive_c/Program\ Files/Altium/AD25/DXP.EXE
LAUNCHER
chmod +x ~/Applications/AltiumDesigner.sh

mkdir -p ~/.local/share/applications
cat <<DESKTOP > ~/.local/share/applications/AltiumDesigner.desktop
[Desktop Entry]
Name=Altium Designer
Comment=Run Altium Designer with Wine
Exec=/home/$USERNAME/Applications/AltiumDesigner.sh
Type=Application
Terminal=false
Icon=altium
Categories=Development;Engineering;Electronics;
DESKTOP

update-desktop-database ~/.local/share/applications

cd /home/$USERNAME/Altium/drive_c/Program\ Files/Altium/AD25
zip -r /home/$USERNAME/Applications/AltiumDesigner25.zip *
EOF

# ============================================================
# Kicad
# ============================================================
print_step "Installing KiCAD"
sudo pacman -Syu kicad --noconfirm

# ============================================================
# LTSpice
# ============================================================
print_step "Installing LTSpice via yay"
sudo -u "$USERNAME" bash <<EOF
  yay -S wine-ltspice --noconfirm
EOF

# ============================================================
# Digital Hardware CAD Installation
# ============================================================

print_step "Installing digital hardware tools and dependencies"
sudo pacman -S gtkwave --noconfirm
sudo -u "$USERNAME" bash <<EOF
  yay -S iverilog --noconfirm
EOF

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
sudo -u "$USERNAME" bash <<EOF
  # Apply user-specific configurations
  echo "Moving user-specific configurations"
  cp -r .config "\$HOME/"
  cp -r .wallpapers "\$HOME/"
  cp -r .bashrc "\$HOME/"
  cp -r .XResources "\$HOME/"
EOF

# ============================================================
# Finalization
# ============================================================

print_step "Setup complete!"
print_step "Only thing missing: git config and download wallpaper engine on steam"
su - "$USERNAME"
sudo reboot
