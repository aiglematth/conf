#!/bin/nu

echo "--- Install paru (AUR helper)\n"
cd /tmp
sudo pacman -Sy --noconfirm --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

echo "--- Install many coo dependencies\n"
cd /tmp
(sudo pacman -Sy --noconfirm --needed 
    bat
    firefox 
    keepassxc 
    code 
    zenith ltrace strace 
    gnu-netcat traceroute whois nmap dnsutils wget curl 
    ghidra jadx
    android-tools android-udev gdb
    btrfs-progs 
    qemu-full 
    docker docker-compose 
    virt-manager
)

(paru -Sy --noconfirm --needed 
    android-studio
)

echo "--- keepassxc-browser should be installed as firefox extension for better integration\n"

echo "Install gef extension for gdb\n"
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"