
update_config_and_keyrings

# user creation
clear
echo "[--root--]:"
passwd
clear
read -p "username: " USERNAME
groupadd sudo
useradd -m -G sudo $USERNAME
passwd $USERNAME

newl

# configure new system as suggested by arch wiki
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
echo "artix" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n\
::1\t\tlocalhost\n\
127.0.0.1\tartix.localdomain artix" >> /etc/hosts

#TODO: write sed command to disable worldwide mirrors and enable br ones excluding the first
sed -i -e 's/^[^#]/#/' /etc/pacman.d/mirrorlist-arch # possible fix? idk
sed -i -e '/Brazil/,/^$/{//!s/^#//' -e '}' /etc/pacman.d/mirrorlist-arch # add all brazilian mirrors
sed -i -e 's_Server = http://br.mirror.archlinux-br.org/$repo/os/$arch_#Server = http://br.mirror.archlinux-br.org/$repo/os/$arch_' /etc/pacman.d/mirrorlist-arch # hardcoded bcuz this mirror is bad and i dont know how to do this efficiently
# copied from LARBS
grep "^Color" /etc/pacman.conf >/dev/null || sed -i "s/^#Color/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# download all packages
pacman -Syyu --ignore xorg-server-xdmx --noconfirm - < pkglist.txt

# this makes my touchpad works, probably others too idk
# btw this is here bcuz cant insert file if there is no folder
echo -e "Section \"Input Class\"\n \
\tIdentifier \"MyTouchpad\"\n \
\tMatchIsTouchpad \"on\"
\tDriver \"libinput\"
\tOption \"Tapping\" \"on\"
\tOption \"HorizontalScrolling\" \"0\"
EndSection" > /etc/X11/xorg.conf.d/30-touchpad.conf

#optout from dotnet telemetry
echo "DOTNET_CLI_TELEMETRY_OPTOUT=1" >> /home/$USERNAME/.bashrc

#so fcitx works properly
echo -e "GTK_IM_MODULE=fcitx\n\
QT_IM_MODULE=fcitx\n\
XMODIFIERS=@im=fcitx" >> /home/$USERNAME/.pam_environment

sed -i 's/# %sudo/%sudo/' /etc/sudoers

# yay dont work as root sooooo whatever
#mkdir /home/${USERNAME}/repo/
#cd /home/${USERNAME}/repo/
#git clone https://aur.archlinux.org/yay.git
#cd yay
#sudo -u $USERNAME makepkg -si
#cd /
#yay -S --noconfirm - < yaylist.txt
newl

echo "ok ill try to do shit now"

newl

# enable s6 services
s6-rc-bundle -c /etc/s6/rc/compiled add default sddm NetworkManager
# install grub
grub-install --recheck $DISK_USED
grub-mkconfig -o /boot/grub/grub.cfg

#exit
