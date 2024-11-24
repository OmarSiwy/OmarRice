#!/bin/bash
set -e

# ============================================================
# Configuration Variables
# ============================================================
REPO_URL="https://github.com/OmarSiwy/OmarRice"
REGION="Canada"
CITY="London"

echo "Starting OmarRice Installation Script..."

# ============================================================
# Detect Boot Mode (UEFI or BIOS)
# ============================================================
if ls /sys/firmware/efi/efivars >/dev/null 2>&1; then
    BOOT_MODE="UEFI"
    echo "System detected as UEFI."
else
    BOOT_MODE="BIOS"
    echo "System detected as BIOS."
fi

# ============================================================
# Partitioning
# ============================================================
echo "Partitioning disk..."
fdisk -l
read -p "Enter the disk to partition (e.g., /dev/sda): " DISK

if [ "$BOOT_MODE" == "UEFI" ]; then
    echo "Creating GPT partitions for UEFI boot..."
    fdisk "$DISK" <<EOF
g # Create a new GPT partition table
n # Boot partition
1

+500M
t
1
n # Swap partition
2

+2000M
t
2
19
n # Root partition
3


w # Write changes
EOF

    echo "Formatting partitions..."
    mkfs.fat -F32 "${DISK}1"  # Boot partition
    mkswap "${DISK}2"         # Swap partition
    mkfs.ext4 "${DISK}3"      # Root partition

    echo "Mounting partitions..."
    mount "${DISK}3" /mnt
    mkdir -p /mnt/boot
    mount "${DISK}1" /mnt/boot
    swapon "${DISK}2"

else
    echo "Creating MBR partitions for BIOS boot..."
    fdisk "$DISK" <<EOF
o # Create a new MBR partition table
n # Swap partition
p
1

+2000M
t
82
n # Root partition
p
2


a # Mark partition 2 as bootable
2
w # Write changes
EOF

    echo "Formatting partitions..."
    mkswap "${DISK}1"         # Swap partition
    mkfs.ext4 "${DISK}2"      # Root partition

    echo "Mounting partitions..."
    mount "${DISK}2" /mnt
    swapon "${DISK}1"
fi

echo "Partitioning complete. Verifying disk layout..."
fdisk -l
sleep 3

# ============================================================
# Base System Installation
# ============================================================
echo "Installing base system..."
pacstrap -K /mnt base base-devel linux linux-firmware e2fsprogs dhcpcd networkmanager sof-firmware git neovim man-db man-pages texinfo

# Special handling for ARM-based devices
if [[ "$(uname -m)" =~ ^(armv7l|aarch64)$ ]]; then
    pacstrap -K /mnt archlinuxarm-keyring || {
        pacman-key --init
        pacman-key --populate
        archlinux-keyring-wkd-sync
    }
fi

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# ============================================================
# System Configuration
# ============================================================
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

# ============================================================
# Bootloader Installation
# ============================================================
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

# ============================================================
# Final Steps
# ============================================================
echo "Unmounting and rebooting..."
umount -R /mnt
echo "Remove the installation disk and press Enter to reboot."
read -p "Press Enter to continue..."
reboot
