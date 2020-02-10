
update_keyrings

# user creation
clear
echo "[--root--]:"
passwd
read -p "[--username: " USERNAME
groupadd sudo
useradd -m -G sudo $USERNAME
passwd $USERNAME

newl

# configure new system
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
echo "artix" > /etc/hostname
echo -e "127.0.0.1\tlocalhost \
	::1\tlocalhost \
	127.0.0.1\tartix.localdomain artix" >> /etc/hosts
sed -e '/Brazil/,/^$/{//!s/^#//' -e '}' /etc/pacman.d/mirrorlist-arch
grep "^Color" /etc/pacman.conf >/dev/null || sed -i "s/^#Color/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# download all packages

pacman -Syy --noconfirm - < pkglist.txt

newl

# install grub
grub-install --recheck $DISK_USED
grub-mkconfig -o /boot/grub/grub.cfg
