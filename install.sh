echo -e "--- Setup keymap\n"
loadkeys fr
setfont ter-132b
localectl set-keymap --no-convert fr

echo -e "--- Setup disk partitions\n"
let "not_used_size = $(blockdev --getsize64 /dev/sda) / (1024*1024) - 1024"
parted /dev/sda --script mklabel gpt
parted /dev/sda --script mkpart primary fat32 1MiB 512MiB
parted /dev/sda --script mkpart primary ext4 512MiB 1024MiB
parted /dev/sda --script mkpart primary btrfs 1024MiB ${not_used_size}MiB

mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2
cryptsetup luksFormat /dev/sda3
cryptsetup luksOpen /dev/sda3 root
mkfs.btrfs /dev/mapper/root
mount /dev/mapper/root /mnt
mount --mkdir /dev/sda2 /mnt/boot
mount --mkdir /dev/sda1 /mnt/boot/efi
pacstrap -K /mnt base base-devel linux linux-firmware openssh git nano sudo
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

echo -e "--- Setup localtime, locales and time\n"
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
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
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --boot-directory=/boot
sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda3:root root=/dev/mapper/root"|g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "--- Install cool dependencies and enable some services\n"
pacman -S networkmanager
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

echo -e "--- Setup keymap again\n"
sudo localectl set-keymap --no-convert fr

echo -e "--- Install rust\n"
sudo pacman -S rust

echo -e "--- Install shells\n"
cargo install nu
sudo bash -c "echo -e '\n/home/aiglematth/.cargo/bin/nu' >> /etc/shells"
chsh -s /home/aiglematth/.cargo/bin/nu
nu
echo '

def create_left_prompt [] {
    let status = if $env.LAST_EXIT_CODE == 0 { 
            echo $"(ansi blue)($env.LAST_EXIT_CODE)(ansi reset)" 
        } else { 
            echo $"(ansi red)($env.LAST_EXIT_CODE)(ansi reset)" 
        }
    echo $"(ansi purple)($env.USER)(ansi reset):[($status)] "
}
$env.PROMPT_COMMAND = { create_left_prompt }


def create_right_prompt [] {
    let time_segment = ([
        (date now | format date "%H:%M | %d %B %Y")
    ] | str join)

    echo $"(ansi red)($time_segment)(ansi reset)"
}
$env.PROMPT_COMMAND_RIGHT = { create_right_prompt }

$env.CARGO_HOME = ($env.HOME | path join .cargo)

$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
]

$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

$env.PATH = (
  $env.PATH
  | split row (char esep)
  | append /usr/local/bin
  | append ($env.CARGO_HOME | path join bin)
  | append ($env.HOME | path join .local bin)
  | uniq
)' out> /home/aiglematth/.config/nushell/env.nu
sudo pacman -S cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python
cargo install alacritty
cargo install zellij
echo 'def start_zellij [] {
  if 'ZELLIJ' not-in ($env | columns) {
    if 'ZELLIJ_AUTO_ATTACH' in ($env | columns) and $env.ZELLIJ_AUTO_ATTACH == 'true' {
      zellij attach -c
    } else {
      zellij
    }

    if 'ZELLIJ_AUTO_EXIT' in ($env | columns) and $env.ZELLIJ_AUTO_EXIT == 'true' {
      exit
    }
  }
}

start_zellij' out> /home/aiglematth/.config/nushell/login.nu

echo "--- Install kde\n"
sudo chmod o+w /opt
sudo pacman -S --needed base-devel xorg sddm plasma kde-applications
systemctl enable sddm.service