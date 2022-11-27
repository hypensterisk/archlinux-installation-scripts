# https://wiki.archlinux.org/title/System_time
hwclock --systohc
timedatectl list-timezones
read -p 'timezone: ' timezone
timedatectl set-timezone "$timezone"

# https://wiki.archlinux.org/title/Locale
localectl list-locales
read -p 'locale: ' locale
read -p 'encoding: ' encoding
echo "$locale $encoding" >> '/etc/locale.gen'
locale-gen
localectl set-locale LANG=$locale
export LANG=$locale

# https://wiki.archlinux.org/title/Network_configuration
read -p 'hostname: ' hostname
hostnamectl set-hostname $hostname
printf "127.0.0.1	localhost\n::1	localhost\n127.0.1.1	$hostname" >> '/etc/hosts'

# https://wiki.archlinux.org/title/Users_and_groups
passwd
read -p 'user: ' user
useradd -m "$user"
passwd "$user"
usermod -aG audio,disk,floppy,input,kvm,optical,scanner,storage,video "$user"

# https://wiki.archlinux.org/title/sudo
pacman -S sudo
echo "$user	ALL=(ALL:ALL) ALL" > '/etc/sudoers'

# https://wiki.archlinux.org/title/Microcode
lscpu
read -p 'processor (amd/intel): ' processor
pacman -S "$processor-ucode"

# https://wiki.archlinux.org/title/GRUB
pacman -S grub efibootmgr os-prober
echo 'GRUB_DISABLE_OS_PROBER=false' > '/etc/default/grub'
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# https://wiki.archlinux.org/title/KDE
pacman -S plasma-desktop sddm
systemctl enable sddm.service
systemctl enable NetworkManager.service

exit