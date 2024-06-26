#!/bin/bash

set -e

# Set default values
KEYMAP="us"
DISK="/dev/sda"
HOSTNAME="archlinux"
USERNAME="user"
PASSWORD="password"

# Set the console keyboard layout
loadkeys $KEYMAP

# Verify the boot mode
if [ ! -d /sys/firmware/efi/efivars ]; then
    echo "EFI variables not found. Are you booted in UEFI mode?"
    exit 1
fi

# Update the system clock
timedatectl set-ntp true

# Partition the disk
parted -s $DISK mklabel gpt
parted -s $DISK mkpart primary fat32 1MiB 261MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary linux-swap 261MiB 4.3GiB
parted -s $DISK mkpart primary ext4 4.3GiB 100%

# Format the partitions
mkfs.fat -F 32 ${DISK}1
mkswap ${DISK}2
mkfs.ext4 ${DISK}3

# Mount the file systems
mount ${DISK}3 /mnt
mkdir -p /mnt/boot/efi
mount ${DISK}1 /mnt/boot/efi
swapon ${DISK}2

# Select the mirrors
reflector --country United States --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install essential packages
pacstrap /mnt base linux linux-firmware gnome

# Configure the system
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Set root password
echo "root:$PASSWORD" | chpasswd

# Create user
useradd -m $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG wheel,audio,video,optical,storage $USERNAME

# Configure sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install and configure GRUB
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable necessary services
systemctl enable gdm
systemctl enable NetworkManager

EOF

# Unmount and reboot
umount -R /mnt
swapoff ${DISK}2
reboot

