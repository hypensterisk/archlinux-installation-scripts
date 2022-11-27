# Set the console keyboard layout
localectl list-keymaps
read -p 'keymap: ' keymap
loadkeys "$keymap"

# Verify the boot mode
ls /sys/firmware/efi/efivars

# Connect to the internet
iwctl device list
read -p 'device: ' device
iwctl station "$device" scan
iwctl station "$device" get-networks
read -p 'SSID: ' SSID
read -p 'passphrase: ' passphrase
iwctl --passphrase "$passphrase" station "$device" connect "$SSID"
ping -c 4 archlinux.org

# Update the system clock
timedatectl status

# Partition the disks
fdisk -l
read -p 'disk: ' disk
cfdisk "$disk"
fdisk -l "$disk"
read -p 'Efi System Partition: ' efi_system_partition
read -p 'Swap Partition: ' swap_partition
read -p 'Root Partition: ' root_partition

# Format the partitions
mkfs.fat -F 32 "$efi_system_partition"
mkswap "$swap_partition"
mkfs.ext4 "$root_partition"

# Mount the file systems
mount "$root_partition" /mnt
mount --mkdir "$efi_system_partition" /mnt/boot/efi
swapon "$swap_partition"

# Select the mirrors
cp "./mirrorlist" "/etc/pacman.d/mirrorlist"

# Install essential packages
pacstrap -K /mnt base linux linux-firmware

# Configure the system
genfstab -U /mnt >> /mnt/etc/fstab
cp "./chroot.sh" "/mnt/chroot.sh"
arch-chroot /mnt "/chroot.sh"
umount "$efi_system_partition"
umount "$root_partition"
swapoff "$swap_partition"
reboot