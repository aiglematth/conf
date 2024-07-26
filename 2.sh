#!/bin/bash

usage() {
    echo "Usage: $0 DISK_PATH"
    echo "    DISK_PATH: The path of the disk (ex: /dev/sda, /dev/nvme0n1)"
}

if [[ $# -ne 1 ]]; then
    usage
    exit -1
fi

DISK_PATH=$(echo $1)
DISK_PARTS=$(echo $1)
if [[ "$DISK_PARTS" =~ "nvme" ]]; then
    DISK_PARTS=$(echo "${DISK_PARTS}p")
fi

echo -e "--- Setup localtime, locales and time\n"
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
sed -i 's/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo LANG=fr_FR.UTF-8 > /etc/locale.conf

echo -e "--- Setup hostname and user\n"
echo nest > /etc/hostname
useradd -m --shell /bin/bash aiglematth
passwd aiglematth

echo -e "--- Setup root password\n"
passwd

echo -e "--- Setup decryption of root partition at boot\n"
sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/g' /etc/mkinitcpio.conf
mkinitcpio -P
pacman -Sy --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --boot-directory=/boot
sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=${DISK_PARTS}3:root root=/dev/mapper/root\"|g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "--- Install network dependencies and enable some services\n"
pacman -Sy --noconfirm networkmanager
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

echo -e '--- Add main user in sudo group\n'
groupadd sudo
usermod -G sudo aiglematth
sed -i 's/# %sudo/%sudo/g' /etc/sudoers

echo -e "--- Preparing reboot\n"
exit
umount -a
reboot