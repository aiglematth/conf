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

echo -e "--- Setup keymap\n"
loadkeys fr
setfont ter-132b
localectl set-keymap --no-convert fr

echo -e "--- Setup disk partitions\n"
let "not_used_size = $(blockdev --getsize64 $DISK_PATH) / (1024*1024) - 1024"
parted $DISK_PATH --script mklabel gpt
parted $DISK_PATH --script mkpart primary fat32 1MiB 512MiB
parted $DISK_PATH --script mkpart primary ext4 512MiB 1024MiB
parted $DISK_PATH --script mkpart primary btrfs 1024MiB ${not_used_size}MiB

mkfs.fat -F 32 ${DISK_PARTS}1
mkfs.ext4 ${DISK_PATH}2
cryptsetup luksFormat ${DISK_PARTS}3
cryptsetup luksOpen ${DISK_PARTS}3 root
mkfs.btrfs /dev/mapper/root
mount /dev/mapper/root /mnt
mount --mkdir ${DISK_PARTS}2 /mnt/boot
mount --mkdir ${DISK_PARTS}1 /mnt/boot/efi
pacstrap -K /mnt base base-devel linux linux-firmware openssh git nano sudo
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "--- NB: If you want to mount others disks at boot, you can reuse the genfstab command later...\n"
arch-chroot /mnt