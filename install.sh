#!/usr/bin/bash
set -e

REPO_URL="https://github.com/OmarSiwy/OmarRice"
REGION="Canada"
CITY="London"

echo "Starting OmarRice Installation Script..."

# Check if in UEFI or BIOS mode
if ls /sys/firmware/efi/efivars >/dev/null 2>&1; then
    BOOT_MODE="UEFI"
    echo "System detected as UEFI."
else
    BOOT_MODE="BIOS"
    echo "System detected as BIOS."
fi

# Partitioning
echo "Partitioning disk..."
fdisk -l
read -p "Enter the disk to partition (e.g., /dev/sda): " DISK

# Start fdisk for partitioning
fdisk "$DISK" <<EOF
g # Create a new GPT partition table (for UEFI)
EOF
if [ "$BOOT_MODE" == "UEFI" ]; then
    fdisk "$DISK" <<EOF
n
1

+300M
t
1
n
2

+512M
t
2
19
n
3


w
EOF

    # Format partitions
    mkfs.fat -F32 "${DISK}1" # Boot partition
    mkswap "${DISK}2"         # Swap partition
    mkfs.ext4 "${DISK}3"      # Root partition

    # Mount partitions
    mount "${DISK}3" /mnt
    mkdir -p /mnt/boot
    mount "${DISK}1" /mnt/boot
    swapon "${DISK}2"

else
    # Create partitions for BIOS
    fdisk "$DISK" <<EOF
o # Create a new MBR partition table
n
p
1

+512M
t
82
n
p
2


a
2
w
EOF

    # Format partitions
    mkswap "${DISK}1"         # Swap partition
    mkfs.ext4 "${DISK}2"      # Root partition

    # Mount partitions
    mount "${DISK}2" /mnt
    swapon "${DISK}1"
fi

echo "Partitioning complete. Verifying disk layout..."
fdisk -l
sleep 3

# Base system installation
echo "Installing base system..."
pacstrap -K /mnt base base-devel linux linux-firmware e2fsprogs dhcpcd networkmanager sof-firmware git neovim man-db man-pages texinfo
if [ "$(uname -m)" == "armv7l" ] || [ "$(uname -m)" == "aarch64" ]; then
    pacstrap -K /mnt archlinuxarm-keyring || {
        pacman-key --init
        pacman-key --populate
        archlinux-keyring-wkd-sync
    }
fi
genfstab -U /mnt >> /mnt/etc/fstab

# System configuration
echo "Configuring system..."
arch-chroot /mnt <<EOF
ln -sf /usr/share/zoneinfo/$REGION/$CITY /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf
echo "arch" > /etc/hostname
cat <<EOL >> /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 arch.localdomain arch
EOL
mkinitcpio -P
echo root:root | chpasswd
EOF

# Add a new user
echo "Adding a new user..."
read -p "Enter a username: " USERNAME
arch-chroot /mnt <<EOF
useradd -m -G wheel,audio,video,storage $USERNAME
echo "$USERNAME:$USERNAME" | chpasswd
EDITOR=nvim visudo <<END
%sudo ALL=(ALL) NOPASSWD: ALL
END
EOF

# Clone ricing repository as the new user
echo "Cloning ricing repository..."
arch-chroot /mnt <<EOF
sudo -u $USERNAME bash <<END
git clone $REPO_URL /home/$USERNAME/OmarRice
END
EOF

# Bootloader installation
echo "Installing GRUB bootloader..."
if [ "$BOOT_MODE" == "UEFI" ]; then
    arch-chroot /mnt <<EOF
pacman -S grub efibootmgr --noconfirm
grub-install --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF
else
    arch-chroot /mnt <<EOF
pacman -S grub --noconfirm
grub-install $DISK
grub-mkconfig -o /boot/grub/grub.cfg
EOF
fi

# Final Steps
echo "Unmounting and rebooting..."
umount -R /mnt
echo "Remove the installation disk and press Enter to reboot."
read -p "Press Enter to reboot."
reboot
