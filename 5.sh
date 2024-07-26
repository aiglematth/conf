#!/bin/nu

echo "--- Install kde\n"
sudo pacman -Sy --noconfirm --needed base-devel xorg sddm plasma kde-applications
sudo systemctl enable sddm.service

echo "--- Deploying kde configuration\n"
cp files/kde/* /home/aiglematth/.config/

echo "--- Deploying sddm configuration\n"
sudo mkdir -p /etc/sddm.conf.d/ /var/lib/sddm/.config/
sudo cp files/sddm/10-wayland.conf /etc/sddm.conf.d/10-wayland.conf
sudo cp ~/.config/kxkbrc /var/lib/sddm/.config/
sudo chown sddm:sddm /var/lib/sddm/.config/kxkbrc