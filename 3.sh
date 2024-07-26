#!/bin/bash

echo -e "--- Setup keymap again\n"
sudo localectl set-keymap --no-convert fr

echo -e "--- Install rust\n"
sudo pacman -Sy --noconfirm rust

echo -e "--- Install shells\n"
sudo pacman -Sy --noconfirm rust nushell
sudo bash -c "echo -e '\n/bin/nu' >> /etc/shells"
chsh -s /bin/nu
nu