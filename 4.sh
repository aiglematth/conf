#!/bin/nu

sudo pacman -Sy --noconfirm cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python alacritty zellij

cp files/nushell/* /home/aiglematth/.config/nushell/